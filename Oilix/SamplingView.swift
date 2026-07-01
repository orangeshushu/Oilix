//
//  SamplingView.swift
//  Oilix
//
//  Created by Guo, Congyu on 12/6/21.
//

import SwiftUI
import Alamofire
import PhotosUI
import MapKit
import ImageIO
import UniformTypeIdentifiers
struct MetaRS: Codable{
    var result: String
    var attempted_username: String
}

struct UploadResponse: Codable {
    let status: Int
    let msg: String
    
    let meta: MetaRS
}
/*
 struct UploadResponse: Codable {
     let status: Int
     let msg: String
     
     let meta: [MetaRes]
 }

struct MetaRes: Codable{
    //struct UploadRecord: Codable{
        let result: String?
        let attempted_username: String
    //}
}
 */
/*
struct UploadResponse: Codable {
    let status: Int
    let msg: String
    let result: Double?
    let attemped_username: String
    enum CodingKeys: String, CodingKey{
        case status = "status"
        case msg = "msg"
        case meta
        enum MetaDataCodingKeys: String, CodingKey{
            case result = "result"
            case attemped_username = "attemped_username"
        }
    }
}
*/
struct SamplingView: View {
    //@State private var showPicker=false
    //@State private var pickedImage=UIImage(systemName: "camera.on.rectangle.fill")!
    @State var attr="No image chossed"
    
    //@Binding var images : [UIImage]
    //@Binding var picker : Bool
    //@State var images : [UIImage] = []
    //@State var locations : [String] = []
    //@State var notes : [String] = []
    //@State var times : [Date] = []
    //@State var samples : [WaterSample] = []
    @StateObject private var samples = WaterSampleViewModel()
    @StateObject var se:Session
    @State var picker = false
    @State var capture = false
    @State var noteSheet = false
    @State var msg = "Uploading"
    @State var finalMsg = ""
    @State var previewN = 0
    @State var showAS=false
    @StateObject var locationManager = LocationManager()
    @State private var gpsOfflineAlert=false
    @State private var startOverAlert=false
    @State private var camDisconnectAlert=false
    @State private var deleteAlert=false
    @State private var locationUpdateAlert=false
    @State private var photoDeniedAlert=false
    @State private var filePicker=false
    @State private var fileImportAlert=false
    @State private var fileImportMessage=""
    @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude:10,//38.952,
            longitude:10//-92.329
        ),
        span:MKCoordinateSpan(
            latitudeDelta:0.2,
            longitudeDelta:0.2
        )
    )
    
    //let dateFormatter=DateFormatter()
    
    @State private var showAlert = false
    //images[0]=UIImage(systemName: "camera.on.rectangle.fill")
    
    /*
     init()
     {
     dateFormatter.dateFormat="y, MMM d, HH:mm:ss"
     }
     */
    var userLatitude: String {
        return "\(locationManager.lastLocation?.coordinate.latitude ?? 0)"
    }
    
    var userLongitude: String {
        return "\(locationManager.lastLocation?.coordinate.longitude ?? 0)"
    }
    
    var body: some View {
        VStack{
            HStack{
                Spacer()
                if(samples.count > 0){
                    Text("\(previewN+1) of \(samples.count)")
                }
                Spacer()
                Button {
                    showAS=true
                } label: {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size:25))
                        .foregroundColor(.blue)
                }
                .confirmationDialog("", isPresented: $showAS, titleVisibility: .hidden) {
                    Button {
                        capture=true
                    } label: {
                        Text("Take From "+deviceName)
                    }
                    Button {
                        picker=true
                    } label: {
                        Text("Choose From Library")
                    }
                    Button {
                        filePicker=true
                    } label: {
                        Text("Choose From Files")
                    }

                    Button("Cancel", role: .cancel){
                        
                    }
                    
                }
                .alert(isPresented: $photoDeniedAlert) {
                    Alert(title: Text("Oilix can't access your photo library"), message: Text("Change \"Photos\" permission to \"All Photos\" if you want to import samples from your photo library."), primaryButton: .default(Text("Go to Settings"), action: {
                        if let url = URL(string:UIApplication.openSettingsURLString) {
                            if UIApplication.shared.canOpenURL(url) {
                               let url =  UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }
                    }), secondaryButton: .destructive(Text("Cancel")))
                }
            }
            .padding(.vertical,10)
            .padding(.horizontal)
            if(samples.count > 0){
                GeometryReader{geometry in
                    VStack{
                        HStack{
                            Spacer()
                            
                            Button{
                                if(previewN-1>=0){
                                    previewN-=1
                                }
                                //print($notes[previewN])
                            }label:{
                                Image(systemName: "chevron.compact.left")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            //.padding(.all)
                            .frame(width: geometry.size.width/16, height: 200)
                            .opacity(previewN==0 ? 0.2 : 1)
                            .disabled(previewN==0)
                            
                            Spacer()
                            
                            Image(uiImage: samples.samples[previewN].image)
                                .resizable()
                                .foregroundColor(lGrey2)
                                .frame(width:geometry.size.width/8*6,height: geometry.size.width/8*6/4*3)
                            
                            Spacer()
                            
                            Button{
                                if(previewN+1<samples.count){
                                    previewN+=1
                                }
                            }label:{
                                Image(systemName: "chevron.compact.right")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            //.padding(.all)
                            .frame(width: geometry.size.width/16, height: 200)
                            .opacity(previewN==samples.count-1 ? 0.2 : 1)
                            .disabled(previewN==samples.count-1)
                            .alert(isPresented: ($camDisconnectAlert)) {
                                Alert(
                                    title: Text("Error"),
                                    message: Text("Disconnect "+deviceName+" before upload.")
                                )
                            }
                            Spacer()
                        }
                        
                        /*
                         Button("Camera roll")
                         {
                         picker=true
                         }
                         .font(.title)
                         .padding(.all)
                         .frame(width:220,height:60)
                         .foregroundColor(.white)
                         .background(.blue)
                         .cornerRadius(35)
                         Button("Capture")
                         {
                         capture=true
                         }
                         .font(.title)
                         .padding(.all)
                         .frame(width:220,height:60)
                         .foregroundColor(.white)
                         .background(.blue)
                         .cornerRadius(35)
                         
                         */
                        HStack{
                            Spacer()
                            Button {
                                //print("delete")
                                if(se.deleteConfirm){
                                    deleteAlert=true
                                }else{
                                    deleteCurrentImage()
                                }
                            } label: {
                                VStack{
                                    Image(systemName: "trash")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                    Text("Delete")
                                        .font(.system(size:15))
                                    Text(" Image ")
                                        .font(.system(size:15))
                                }
                            }
                            .padding(.all)
                            Divider()
                            Button {
                                //print("note")
                                noteSheet=true
                            } label: {
                                VStack{
                                    Image(systemName: "note.text")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                    Text("Edit")
                                        .font(.system(size:15))
                                    Text("Note")
                                        .font(.system(size:15))
                                }
                            }
                            .padding(.all)
                            Divider()
                            /*
                            Button {
                                //print("online")
                                samples.onlineAnalyse(i: previewN)
                            } label: {
                                VStack{
                                    Image(systemName: "globe.americas")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                    Text("Online")
                                    Text("Analyze")
                                }
                            }
                            .padding(.all)
                            .disabled(samples.samples[previewN].online)
                             */
                            Button {
                                //print(region.center.latitude)
                                region.center=History.getLocation(locStr: samples.samples[previewN].location) ?? CLLocationCoordinate2D(
                                    latitude:0,
                                    longitude:0
                                    )
                                //region.center.latitude=0
                                //print(region.center.latitude)
                                locationUpdateAlert=true
                            } label: {
                                VStack{
                                    Image(systemName: "location.viewfinder")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                    Text("Edit")
                                        .font(.system(size:15))
                                    Text("Location")
                                        .font(.system(size:15))
                                }
                            }
                            .padding(.all)
                            /*
                            .alert(isPresented: $locationUpdateAlert) {
                                Alert(title: Text("Caution"), message: Text("Overwrite this sample's location info with current location?"), primaryButton: .destructive(Text("Overwrite"), action: {
                                    samples.samples[previewN].location = "\(userLatitude),\(userLongitude)"
                                    
                                }), secondaryButton: .default(Text("Cancel")))
                                
                                
                            }*/
                            .sheet(isPresented: $locationUpdateAlert, content:{ LocationEditView(ent: $locationUpdateAlert, samples: samples, ind: $previewN, region: $region)})
                            Spacer()
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 100)
                        
                        
                        HStack{
                            Image(systemName: "calendar.badge.clock")
                            //Text("time")
                            //Text(dateFormatter.string(from: times[previewN]))
                            Text(samples.samples[previewN].time)
                            Spacer()
                        }
                        .padding([.leading,.bottom], 10)
                        HStack{
                            Image(systemName: "location")
                            if(samples.samples[previewN].location != "0.0,0.0"){
                                Text(samples.samples[previewN].location)
                            }else{
                                Text("No GPS data")
                                Spacer()
                                Button {
                                    if(locationManager.locationStatus == .authorizedWhenInUse || locationManager.locationStatus == .authorizedAlways){
                                        samples.samples[previewN].location="\(userLatitude),\(userLongitude)"
                                    }
                                    else{
                                        gpsOfflineAlert=true
                                    }
                                } label: {
                                    Text("Use current location")
                                }
                                .alert(isPresented: $gpsOfflineAlert) {
                                    Alert(title: Text("Current Location Not Available"), message: Text(locationManager.statusString), primaryButton: .default(Text("Go to Settings"), action: {
                                        if let url = URL(string:UIApplication.openSettingsURLString) {
                                            if UIApplication.shared.canOpenURL(url) {
                                                let url =  UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            }
                                        }
                                    }), secondaryButton: .destructive(Text("Cancel")))
                                    
                                    
                                }
                                
                            }
                            Spacer()
                        }
                        .padding([.leading,.bottom], 10)
                        HStack{
                            Image(systemName: "testtube.2")
                            Text(samples.samples[previewN].result)
                            if(samples.samples[previewN].online){
                                Text(" (online result)")
                            }else{
                                Text("local result not available")
                            }
                            Spacer()
                        }
                        .padding([.leading,.bottom], 10)
                        HStack{
                            Image(systemName: "note.text")
                            Text(samples.samples[previewN].note)
                            Spacer()
                        }
                        .padding([.leading,.bottom], 10)
                        
                        
                        Spacer()
                        Button
                        {
                            let camUrl=URL(string: cameraURL+"stat")!
                            AF.request(camUrl, method: .get)
                            {
                                urlRequest in
                                urlRequest.timeoutInterval=1
                            }
                            .response{
                                response in
                                switch(response.result){
                                case .success:
                                    camDisconnectAlert=true
                                    break
                                case .failure(let error):
                                    msg="Uploading"
                                    showAlert = true
                                    let imgCount = samples.count
                                    
                                    let userDefault = UserDefaults()
                                    //let authtoken = userDefault.value(forKey: "access") as! String
                                    let username = userDefault.value(forKey: "username") as! String
                                    let password = userDefault.value(forKey: "password") as! String
                                    //print("defTest")
                                    //print(username)
                                    //refreshtoken(username: username, password: password)
                                    //print("refresh finished")
                                    //let headers: HTTPHeaders = ["Content-type": "image/jpeg", "Authorization":"Bearer "+authtoken ]
                                    //let headers: HTTPHeaders = ["gps": "testlocation", "notes":"test3 "]
                                    //let param:[String:Any] = ["gps": "testlocation", "notes":"test4 "]
                                    var sucCount=0
                                    finalMsg="Finished.\n"
                                    for i in 0..<imgCount
                                    {
                                        var emptyMeta:MetaRS=MetaRS(result: "-1", attempted_username: "n/a")
                                        var j1:UploadResponse=UploadResponse(status: 9, msg: "n/a", meta: emptyMeta)
                                        msg="Upolading \(sucCount+1) of \(imgCount)"
                                        guard let imageData = samples.samples[i].image.jpegData(compressionQuality: 1) else { print("no data"); return;}
                                        let uuid = NSUUID().uuidString
                                        //AF.upload(imageData,to:"http://45.63.68.161/api/upload/"+uuid+".jpeg",method: .put,headers: headers)
                                        //AF.upload(imageData,to:"http://47.100.22.28/photoupload2/"+uuid+".jpeg",method: .put,headers: headers)
                                        AF.upload(multipartFormData: {(multipartFormData) in multipartFormData.append(imageData, withName: "photo", fileName:uuid+".jpeg")
                                            /*
                                             for (key, value) in param{
                                             multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key)
                                             }*/
                                            multipartFormData.append(samples.samples[i].location.data(using: String.Encoding.utf8)!, withName: "gps")
                                            multipartFormData.append(samples.samples[i].note.data(using: String.Encoding.utf8)!, withName: "notes")
                                        }, to: serverURL+"photoupload")
                                        //}, to: "https://wateroil.itongue.cn/photoupload")
                                        //}, to: "http://47.100.22.28/photoupload")
                                        .responseJSON { AFdata in
                                            do {
                                                if(AFdata.data==nil){
                                                    print("AFdata.data is nil")
                                                    return
                                                }
                                                
                                                print(String(decoding:AFdata.data!, as: UTF8.self))
                                                guard let jsonObject = try JSONSerialization.jsonObject(with: AFdata.data!) as? [String: Any] else {
                                                    print("Error: Cannot convert data to JSON object")
                                                    return
                                                }
                                                guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                                                    print("Error: Cannot convert JSON object to Pretty JSON data")
                                                    return
                                                }
                                                j1 = try JSONDecoder().decode(UploadResponse.self, from: prettyJsonData)
                                                //print(j1.msg)
                                            } catch {
                                                print("Error: Trying to convert JSON data to string")
                                                //return
                                            }
                                            //showsAlert=false
                                            sucCount+=1
                                            if(j1.status==0){
                                                samples.samples[i].result=j1.meta.result
                                                samples.samples[i].online=true
                                                
                                            }else{
                                                //msg="Failed1"
                                                finalMsg+=j1.msg
                                                finalMsg+="\n"
                                            }
                                            if(sucCount==imgCount){
                                                //msg="Success"
                                                msg=finalMsg
                                            }else{
                                                msg="Upolading \(sucCount+1) of \(imgCount)"
                                            }
                                            //self.err=false
                                        }
                                            /*.responseString { response in
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
                                            }*/
                                        //let response2: AFDataResponse<String>
                                    }
                                    /*
                                     if(sucCount==imgCount){
                                     //msg="Success"
                                     }
                                     else{
                                     print(sucCount,",",imgCount)
                                     //msg="Failed2"
                                     }
                                     */
                                    
                                    break
                                }
                            }
                        }
                    label: {
                        Label("Upload \(samples.count) images", systemImage: "icloud.and.arrow.up")
                    }
                    .font(.title2)
                    .padding(.all)
                    .frame(width:320,height:60)
                    .foregroundColor(.white)
                    .background(.blue)
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
                        Spacer()
                    }
                    
                }
                
                
            }
            else{
                VStack{
                    Text("Welcome to Oilix!")
                        .font(.title)
                    HStack{
                        Text("Tap \"")
                            .font(.title)
                        Image(systemName: "plus.square.on.square")
                            .font(.system(size:25))
                            .foregroundColor(.blue)
                        Text("\" to start.")
                            .font(.title)
                    }
                    HStack{
                        VStack{
                            Image(systemName: "sunrise")
                                .resizable()
                                .foregroundColor(lGrey2)
                                .frame(width:150,height: 120)
                            
                            Image(systemName: "photo")
                                .resizable()
                                .foregroundColor(lGrey2)
                                .frame(width:150,height: 120)
                        }
                        Image(systemName: "rectangle.portrait")
                            .resizable()
                            .foregroundColor(lGrey2)
                            .frame(width:150,height: 240)
                    }/*
                    Image(systemName: "ruler.fill")
                        .resizable()
                        .foregroundColor(lGrey2)
                        .frame(width:300,height: 120)*/
                    HStack{
                        Image(systemName: "folder.fill")
                            .resizable()
                            .foregroundColor(lGrey2)
                            .frame(width:150,height: 120)
                        Image(systemName: "photo")
                            .resizable()
                            .foregroundColor(lGrey2)
                            .frame(width:150,height: 120)
                    }
                }
                Spacer()
            }
        }
        .navigationTitle("Upload")
        .alert(isPresented: $fileImportAlert) {
            Alert(
                title: Text("Import Failed"),
                message: Text(fileImportMessage),
                dismissButton: .default(Text("Dismiss"))
            )
        }
        .confirmationDialog("Delete this image?", isPresented: $deleteAlert, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteCurrentImage()
            }
            Button("Cancel", role: .cancel) {
            }
        }
        .sheet(isPresented: $picker, content: {
            //PhotoPicker(pickedImage: $pickedImage)
            //ImagePicker(images:$images, locations:$locations, notes:$notes, times:$times, picker:$picker,  attr: $attr)
            ImagePicker(picker: $picker, samples: samples)
        })
        .sheet(isPresented: $capture) {
            //CameraView(images:$images, locations:$locations, notes:$notes, times:$times, picker:$picker, isPresented: $capture)
            CameraView(samples: samples, picker: $picker, isPresented: $capture)
        }
        .sheet(isPresented: $noteSheet) {
            NoteView(samples: samples, i: $previewN, noteSheet: $noteSheet)
        }
        .fileImporter(isPresented: $filePicker, allowedContentTypes: [.image], allowsMultipleSelection: true) { result in
            importFiles(result)
        }
        .onChange(of: samples.count) { _ in
            clampPreviewIndex()
        }
        //pickedImage
        //let nsd=pickedImage.jpegData(compressionQuality: 1)
        
        //let metadata =  CGImageSourceCopyPropertiesAtIndex(cgis,0,nil)
        //let imgexif=CFDictionaryGetValue(metadata, kCGImagePropertyExifDictionary)
    }
    
    private func deleteCurrentImage() {
        guard samples.count > 0 else {
            previewN = 0
            return
        }
        
        let deletedIndex = min(previewN, samples.count - 1)
        let remainingCount = samples.count - 1
        guard samples.delete(deletedIndex) else {
            clampPreviewIndex()
            return
        }
        
        if remainingCount == 0 {
            previewN = 0
        } else {
            previewN = min(deletedIndex, remainingCount - 1)
        }
    }
    
    private func clampPreviewIndex() {
        if samples.count == 0 {
            previewN = 0
        } else {
            previewN = min(max(previewN, 0), samples.count - 1)
        }
    }
    
    private func importFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            var importedCount = 0
            for url in urls {
                if importFile(url) {
                    importedCount += 1
                }
            }
            if !urls.isEmpty && importedCount == 0 {
                fileImportMessage = "No supported images were imported from Files."
                fileImportAlert = true
            }
        case .failure:
            fileImportMessage = "Oilix couldn't read the selected file."
            fileImportAlert = true
        }
    }
    
    private func importFile(_ url: URL) -> Bool {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let imageData = try? Data(contentsOf: url),
              let image = UIImage(data: imageData) else {
            return false
        }
        
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil)
        let metadata = imageSource.flatMap {
            CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any]
        }
        
        DispatchQueue.main.async {
            samples.add(
                image: image,
                location: fileLocation(from: metadata),
                times: fileDate(from: url, metadata: metadata)
            )
        }
        return true
    }
    
    private func fileLocation(from metadata: [CFString: Any]?) -> String {
        guard let gps = metadata?[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let latitudeValue = gps[kCGImagePropertyGPSLatitude] as? NSNumber,
              let longitudeValue = gps[kCGImagePropertyGPSLongitude] as? NSNumber else {
            return "0.0,0.0"
        }
        
        var latitude = latitudeValue.doubleValue
        var longitude = longitudeValue.doubleValue
        
        if let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
           latitudeRef.uppercased() == "S" {
            latitude *= -1
        }
        if let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String,
           longitudeRef.uppercased() == "W" {
            longitude *= -1
        }
        
        return "\(latitude),\(longitude)"
    }
    
    private func fileDate(from url: URL, metadata: [CFString: Any]?) -> Date {
        if let exif = metadata?[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let originalDate = exif[kCGImagePropertyExifDateTimeOriginal] as? String,
           let parsedDate = parseImageDate(originalDate) {
            return parsedDate
        }
        
        if let tiff = metadata?[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let tiffDate = tiff[kCGImagePropertyTIFFDateTime] as? String,
           let parsedDate = parseImageDate(tiffDate) {
            return parsedDate
        }
        
        let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        return resourceValues?.creationDate ?? resourceValues?.contentModificationDate ?? Date()
    }
    
    private func parseImageDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: value)
    }
}


struct SamplingView_Previews: PreviewProvider {
    static var previews: some View {
        let se=Session()
        SamplingView(se:se)
    }
}
