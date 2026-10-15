//
//  WaterSample.swift
//  Oilix
//
//  Created by Guo, Congyu on 7/8/22.
//

import Foundation
import SwiftUI
import Alamofire
import CoreML
import Vision

@MainActor
class WaterSampleViewModel: ObservableObject{
    @Published var samples : [WaterSample] = []
    @Published private(set) var isImporting = false
    @Published private(set) var importStatus = ""
    private(set) var importGeneration = 0
    private var importRequest: Progress?

    func beginImport(total: Int) -> Int {
        cancelImport()
        isImporting = true
        importStatus = "Importing 1 of \(total) images..."
        return importGeneration
    }

    func trackImport(_ progress: Progress, generation: Int) {
        if isImporting && generation == importGeneration { importRequest = progress }
        else { progress.cancel() }
    }

    func updateImport(completed: Int, total: Int, generation: Int) {
        guard generation == importGeneration, isImporting else { return }
        if completed >= total { isImporting = false; importRequest = nil; importStatus = "" }
        else { importStatus = "Importing \(completed + 1) of \(total) images..." }
    }

    func cancelImport() {
        importGeneration += 1
        importRequest?.cancel()
        importRequest = nil
        isImporting = false
        importStatus = ""
    }
    var count:Int{
        return samples.count
    }
    
    func add(image: UIImage, location: String, times: Date){
        samples.append(WaterSample(image: image, location: location, times: times))
        //print("added")
        //localAnalyse(samples.count-1)//disabled until we have better local model
    }
    
    @discardableResult
    func delete(_ i: Int) -> Bool{
        guard samples.indices.contains(i) else {
            return false
        }
        
        samples.remove(at: i)
        return true
    }
    
    func deleteAll(){
        samples.removeAll()
    }
    
    func localAnalyse(_ i:Int){
        //samples[i].result="error"
        do{
            let config=MLModelConfiguration()
            config.computeUnits = .cpuOnly//if not, init() will fail on iphone
            let model = try water_predict_bgr(configuration: config)
            
//            let model = water_predict_bgr()
            let pixelBuffer=samples[i].image.pixelBuffer(width: 512 , height: 512)!
            let predition = try model.prediction(image:pixelBuffer)
            print(predition.predict_val[0])
            samples[i].result = "\(predition.predict_val[0])"//may cause crash?
        }catch{
            print("local predict error")
            samples[i].result="error"
        }
        
    }
    
    func localAnalyse2(_ i:Int){
        let model: VNCoreMLModel = {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .cpuOnly//if not, init() will fail on iphone
                return try VNCoreMLModel(for: water_predict_bgr(configuration: config).model)
            } catch {
                fatalError("Can not import model")
            }
        }()
        
        let request = VNCoreMLRequest(model: model) { (request, err) in
            
            if let results = request.results as? [VNCoreMLFeatureValueObservation] {
                print("your results are of type VNCoreMLFeatureValueObservation")
                guard let result = results.first?.featureValue.multiArrayValue![0] else {
                    fatalError("Not output")
                }
                print(result)
                let pred_val = "\(result)"
                
                DispatchQueue.main.async(execute: {
                    self.samples[i].result=pred_val
                    //self.label.text = pred_val
                })
                 
            }
        }
    
        request.imageCropAndScaleOption = .centerCrop
        
        let pixelBuffer=samples[i].image.pixelBuffer(width: 512 , height: 512)!
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        
        do {
            try handler.perform([request])
        } catch  {
            print(error)
        }
        
        
       
        
    }
    
    func onlineAnalyse(i:Int){
        /*
        let uuid = NSUUID().uuidString
        let url="http://66.42.127.2:8003/webAPI"
        var items: [UIImage] = []
        items.append(samples[i].image)
        getTestResult(uid: uuid, url: url, images: items) { [self] result in
        //guard let self = self else { return }
        }*/
        samples[i].result="24K pure"
        samples[i].online=true;
        //self.objectWillChange.send()
    }
    
    func getTestResult(i:Int, uid: String, url: String, images: [UIImage], completed: @escaping (Swift.Result<TestResult, Error>) -> Void) {
        
        let headers: HTTPHeaders = ["Content-type": "multipart/form-data"]
        //let te:TestResult
        print("upload start")
        print(images.count)
        AF.upload(
            multipartFormData: {formData in
                for image in images {
                    guard let imageData = image.jpegData(compressionQuality: 1) else {return}
                    
                    formData.append(imageData, withName: "images", fileName: "\(uid)" + "\(Date().timeIntervalSince1970).jpeg", mimeType: "image/jpeg")
                }},
            to: url, method: .post, headers: headers)
            .responseString { response in
                print("respond")
                switch response.result {
                case .success(let upload):
                    //upload { response in
                    print("successed")
                    if let response = response.data {
                        do {
                            let decoder = JSONDecoder()
                            let testResult = try decoder.decode(TestResult.self, from: response)
                            completed(.success(testResult))
                            print(testResult.results[0].prediction)
                            self.samples[i].note=testResult.results[0].prediction
                        } catch {
                            completed(.failure(error))
                        }
                        //       }
                    }
                case .failure(let error):
                    print("failed")
                    completed(.failure(error))
                }
            }
        //attr="Analyzing..."
    }
}

struct WaterSample: Identifiable {
    let id = UUID()
    var image : UIImage
    var location : String
    var note : String
    var time : String
    var result : String
    var online : Bool
    
    init(image: UIImage, location: String, times: Date){
        self.image=image
        self.location=location
        self.note=""//"\(Int.random(in: 1...100))"
        let dateFormatter=DateFormatter()
        dateFormatter.dateFormat="y, MMM d, HH:mm:ss"
        self.time=dateFormatter.string(from: times)
        online=false
        self.result=""
        //localAnalyse()
    }
    
    
    
    

}
