//
//  AnalyzingView.swift
//  Oilix
//
//  Created by Guo, Congyu on 12/6/21.
//

import SwiftUI
import Alamofire

struct TestResult: Codable {
    let error: Bool
    let errorDescription: String
    let results: [Post]
    
    enum CodingKeys: String, CodingKey {
        case error
        case results
        case errorDescription = "error_description"
    }
}

struct Post: Codable {
    let location: String
    let prediction: String
    let lower: Double
    let upper: Double
    let time: String
    var note: String?
    
    enum CodingKeys: String, CodingKey {
        case location
        case prediction
        case lower = "lower_test_prediction"
        case upper = "upperprediction"
        case time
        case note
    }
}
/*
struct AnalyzingView: View {
    //@State private var showPicker=false
    //@State private var pickedImage=UIImage(systemName: "camera.on.rectangle.fill")!
    @State var attr="No image chossed"
    
    //@Binding var images : [UIImage]
    //@Binding var picker : Bool
    @State var images : [UIImage] = []
    @State var locations : [String] = []
    @State var notes : [String] = []
    @State var times : [Date] = []
    @State var picker = false
    @State var msg = "Uploading"
    @State var previewN = 0
    
    @State private var showAlert = false
    //images[0]=UIImage(systemName: "camera.on.rectangle.fill")
    var body: some View {
        VStack{
            //Image(uiImage: pickedImage)
            //Image(systemName: "camera.on.rectangle.fill")
            if(images.count > 0){
                Image(uiImage: images[previewN])
                    .resizable()
                    .foregroundColor(lGrey2)
                    .frame(width:350,height: 300)
                HStack{
                    Button{
                        if(previewN-1>=0){
                            previewN-=1
                        }
                    }label:{
                        Image(systemName: "arrow.left.square")
                            .resizable()
                    }
                    .padding(.all)
                    .frame(width: 100, height: 100)
                    
                    Button{
                        if(previewN+1<images.count){
                            previewN+=1
                        }
                    }label:{
                        Image(systemName: "arrow.right.square")
                            .resizable()
                    }
                    .padding(.all)
                    .frame(width: 100, height: 100)
                }
            }
            else{
                Image(systemName: "photo")
                    .resizable()
                //.foregroundColor(lGrey2)
                    .frame(width:350,height: 300)
            }
            
            Button("Image Picker")
            {
                picker=true
            }
            .font(.title)
            .padding(.all)
            .frame(width:220,height:60)
            .foregroundColor(.white)
            .background(.blue)
            .cornerRadius(35)
            Button("Online Analyze")
            {
                /*
                 msg="Uploading"
                 showAlert = true
                 let imgCount = images.count
                 
                 let userDefault = UserDefaults()
                 let authtoken = userDefault.value(forKey: "access") as! String
                 let username = userDefault.value(forKey: "username") as! String
                 let password = userDefault.value(forKey: "password") as! String
                 //print("defTest")
                 //print(username)
                 //refreshtoken(username: username, password: password)
                 //print("refresh finished")
                 let headers: HTTPHeaders = ["Content-type": "image/jpeg", "Authorization":"Bearer "+authtoken ]
                 var sucCount=0
                 for i in 0..<imgCount
                 {
                 msg="Upolading \(sucCount+1) of \(imgCount)"
                 guard let imageData = images[i].jpegData(compressionQuality: 1) else { print("no data"); return;}
                 let uuid = NSUUID().uuidString
                 AF.upload( imageData, to:"http://45.63.68.161/api/upload/"+uuid+".jpeg",method: .put,headers: headers)
                 .responseString { response in
                 debugPrint("Response: \(response)")
                 //showAlert=false
                 switch response.result{
                 case .success:
                 //completed(.success(response.description))
                 //msg="Done!"
                 //showAlert=true
                 sucCount+=1
                 if(sucCount==imgCount){
                 msg="Success"
                 }
                 else{
                 msg="Upolading \(sucCount+1) of \(imgCount)"
                 }
                 break
                 case .failure(let error):
                 //completed(.failure(error))
                 msg="Failed1"
                 //showAlert=true
                 break
                 
                 }
                 }
                 //let response2: AFDataResponse<String>
                 }
                 */
                /*
                 if(sucCount==imgCount){
                 //msg="Success"
                 }
                 else{
                 print(sucCount,",",imgCount)
                 //msg="Failed2"
                 }
                 */
                
                //attr="Uploading..."
                attr="to be continued"
                var items: [UIImage] = []
                //let img=UIImage(named: "cat.jpg")!
                if images.count>0
                {
                    let img=images[previewN]
                    items.append(img)
                    let uuid = NSUUID().uuidString
                    print("online analyze")
                    /*
                     getTestResult(uid: uuid, url: "http://66.42.127.2:8003/webAPI", images: items) { [self] result in
                     //guard let self = self else { return }
                     }
                     */
                }
                else{
                    attr = "Please choose images first"
                }
            }
            .font(.title)
            .padding(.all)
            .frame(width:220,height:60)
            .foregroundColor(.white)
            //.background(.blue)
            .background(.gray)
            .cornerRadius(35)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Uploading"),
                    message: Text(msg),//Text(">>............"),
                    /*
                     primaryButton: .destructive(
                     Text("Cancel"),
                     action:
                     {
                     showAlert = false
                     }
                     ),
                     secondaryButton: .default(
                     Text("Pause")
                     )*/
                    dismissButton: .default(Text("Dismiss"))
                )
            }
            
            
            Button("Local Analyze")
            {
                
                if images.count>0
                {
                    attr="Uploading..."
                    var items: [UIImage] = []
                    //let img=UIImage(named: "cat.jpg")!
                    let img=images[previewN]
                    //items.append(img)
                    //let uuid = NSUUID().uuidString
                    //print("online analyze")
                    //getTestResult(uid: uuid, url: "http://66.42.127.2:8003/webAPI", images: items) { [self] result in
                    //guard let self = self else { return }
                    //}
                    
                    
                    
                    
                    let model = water_predict_bgr()
                    //let model = WaterImage()
                    //let img = UIImage(named: "300b.JPG")!
                    //let pixelBuffer=img.pixelBuffer(width:224,height:224)
                    //let resizedImage=img.resizeTo()
                    let pixelBuffer=img.pixelBuffer(width: 512 , height: 512)!
                    let predition = try?model.prediction(image:pixelBuffer)
                    //let top5=top(5,predition.scoresShapedArray)
                    //to do
                    //let ttt: water_predict_bgrOutput
                    //print(predition!.predict_val)
                    attr = "\(predition!.predict_val[0])"
                }
                else{
                    attr = "Please choose images first"
                }
                
            }
            .font(.title)
            .padding(.all)
            .frame(width:220,height:60)
            .foregroundColor(.white)
            .background(.blue)
            .cornerRadius(35)
            
            
            
            //Text($attr)
            TextField("attr",text:$attr)
                .padding()
                .foregroundColor(.black)
                .background(lGrey)
                .cornerRadius(10)
                .autocapitalization(UITextAutocapitalizationType.none)
                .disabled(true)
                .multilineTextAlignment(.center)
            /*
             TextField("n",text:\($images.count))
             .padding()
             .foregroundColor(.black)
             .background(lGrey)
             .cornerRadius(10)
             .autocapitalization(UITextAutocapitalizationType.none)
             */
            
            
            /*
             Button("test exif")
             {
             //print("pressed")
             //let nsd=pickedImage.jpegData(compressionQuality: 1.0)
             
             let nsd=images[0].jpegData(compressionQuality: 1.0)
             //guard let cgis=CGImageSourceCreateWithData((CFData).self as! CFData, nsd as! CFDictionary) else { return }
             //let cgis:CGImageSource=CGImageSourceCreateWithData( nsd as! CFData, nil) ?? CGImageSource.self as! CGImageSource
             let cgis = CGImageSourceCreateWithData(nsd! as CFData, nil)!
             //let tm:NSDictionary?=CGImageSourceCopyPropertiesAtIndex(cgis ?? <#default value#>,0,nil);
             //var cgis: CGImageSourceRef = CGImageSourceCreateWithData((nsd as? CFMutableDataRef), nil)
             var tm = CGImageSourceCopyPropertiesAtIndex(cgis, 0, nil) as? [AnyHashable: Any]
             //let tv=tm?["kCGImagePropertyFileSize"]
             let tv=tm?[attr]
             //print(attr)
             print(tm)
             }
             .font(.title)
             .padding(.all)
             */
        }
        .navigationTitle("Upload")
        .sheet(isPresented: $picker, content: {
            //PhotoPicker(pickedImage: $pickedImage)
            //ImagePicker(images:$images, locations:$locations, notes:$notes, times:$times, picker:$picker,  attr: $attr)
        })
        //pickedImage
        //let nsd=pickedImage.jpegData(compressionQuality: 1)
        
        //let metadata =  CGImageSourceCopyPropertiesAtIndex(cgis,0,nil)
        //let imgexif=CFDictionaryGetValue(metadata, kCGImagePropertyExifDictionary)
    }
    
    func getTestResult(uid: String, url: String, images: [UIImage], completed: @escaping (Swift.Result<TestResult, Error>) -> Void) {
        
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
                            attr=testResult.results[0].prediction
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
        attr="Analyzing..."
    }
    
}

struct AnalyzingView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyzingView()
    }
}
*/
