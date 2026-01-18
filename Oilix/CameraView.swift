//
//  CameraView.swift
//  Oilix
//
//  Created by Guo, Congyu on 6/3/22.
//

import SwiftUI
import Combine
import Alamofire
import AudioToolbox

class ImageLoader: ObservableObject {
    var didChange = PassthroughSubject<Data, Never>()
    var data = Data() {
        didSet {
            didChange.send(data)
        }
    }
    var task: URLSessionDataTask?
    init() {
        //guard let url = URL(string: urlString) else { return }
        
        //res()
    }
    
    func res(){
        //guard let url = URL(string: "http://192.168.2.8:8888/out.jpg") else { return }
        //guard let url = URL(string: "http://192.168.2.12:8080/?action=snapshot") else { return }
        //guard let url = URL(string: cameraURL+"pic.jpg") else { return }
        guard let url = URL(string: cameraURL+"capture") else { return }
        //guard let url = URL(string: "http://192.168.2.17/capture") else { return }///////////////////////////
        task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.data = data
            }
        }
        if(task != nil)
        {
            task!.resume()
        }
    }
}

struct CameraView: View {
    //@ObservedObject var imageLoader:ImageLoader
    @ObservedObject var imageLoader = ImageLoader()
    @State var image:UIImage = UIImage()
    //@State var images : [UIImage] = []
    //@Binding var images : [UIImage]
    //@Binding var locations : [String]
    //@Binding var notes : [String]
    //@Binding var times : [Date]
    @StateObject var samples : WaterSampleViewModel
    @Binding var picker : Bool
    @State var previewN = 0
    @StateObject var locationManager = LocationManager()
    @State var active=false
    @State var camStat=false
    @State var gpsStat=false
    
    @State private var camOfflineAlert=false
    @State private var gpsOfflineAlert=false
    @State private var gpsOnlineAlert=false
    
    @Binding var isPresented : Bool
    
    @State private var shutter=false
    @State private var progressing=false
    
    var iconSize=CGFloat(30)
    
    var userLatitude: String {
        return "\(locationManager.lastLocation?.coordinate.latitude ?? 0)"
    }
    
    var userLongitude: String {
        return "\(locationManager.lastLocation?.coordinate.longitude ?? 0)"
    }
    
    //let url=URL(string: "http://192.168.2.8:8888/out.jpg")
    //init() {
    
    //imageLoader = ImageLoader(urlString:"http://192.168.2.8:8888/out.jpg")
    //}
    /*
     @State var didChange = PassthroughSubject<Data, Never>()
     @State var data2 = Data() {
     didSet {
     didChange.send(data2)
     }
     }
     */
    var body: some View {
        ZStack{
            Color.black.edgesIgnoringSafeArea(.all)
            VStack{
                //Spacer()
                HStack{
                    if(gpsStat){
                        /*
                         Image(systemName: "location")
                         .resizable()
                         .foregroundColor(.blue)
                         .aspectRatio(contentMode: .fit)
                         .frame(width: 40, height: 40)
                         
                         Spacer()
                         Text("\(userLatitude),\(userLongitude)")
                         .font(.system(size:20))
                         */
                        Button{
                            gpsOnlineAlert=true
                        }label: {
                            Image(systemName: "location")
                                .resizable()
                                .foregroundColor(.blue)
                                .aspectRatio(contentMode: .fit)
                        }
                        .frame(width: iconSize, height: iconSize)
                        .padding(.all)
                        .alert(isPresented: $gpsOnlineAlert) {
                            Alert(title: Text("Current location:"), message: Text("\(userLatitude),\(userLongitude)"), dismissButton: .default(Text("dismiss")))
                        }
                    }
                    else{
                        /*
                         Image(systemName: "location.slash")
                         .resizable()
                         .foregroundColor(.red)
                         .aspectRatio(contentMode: .fit)
                         .frame(width: 40, height: 40)
                         
                         Spacer()
                         Text(locationManager.statusString)
                         .font(.system(size:20))
                         */
                        Button{
                            gpsOfflineAlert=true
                        }label: {
                            Image(systemName: "location.slash")
                                .resizable()
                                .foregroundColor(.red)
                                .aspectRatio(contentMode: .fit)
                        }
                        .frame(width: iconSize, height: iconSize)
                        .padding(.all)
                        .alert(isPresented: $gpsOfflineAlert) {
                            //Alert(title: Text("Location unavailable"), message: Text(locationManager.statusString), dismissButton: .default(Text("dismiss")))
                            
                            
                            Alert(title: Text("Current Location Not Available"), message: Text(locationManager.statusString), primaryButton: .default(Text("Go to Settings"), action: {
                                if let url = URL(string:UIApplication.openSettingsURLString) {
                                    if UIApplication.shared.canOpenURL(url) {
                                       let url =  UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    }
                                }
                            }), secondaryButton: .destructive(Text("Cancel")))
                             
                            
                        }
                    }
                    //}
                    //HStack{
                    if(camStat){
                        Image(systemName: "video")
                            .resizable()
                            .foregroundColor(.blue)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .padding(.all)
                        /*
                         Spacer()
                         Text("Rishi's Device connected")
                         .font(.system(size:20))
                         */
                    }
                    else{
                        /*
                         Image(systemName: "video.slash")
                         .resizable()
                         .foregroundColor(.red)
                         .aspectRatio(contentMode: .fit)
                         .frame(width: 40, height: 40)
                         
                         Spacer()
                         Text("Rishi's Device not found!")
                         .font(.system(size:20))
                         */
                        Button{
                            camOfflineAlert=true
                        }label: {
                            Image(systemName: "video.slash")
                                .resizable()
                                .foregroundColor(.red)
                                .aspectRatio(contentMode: .fit)
                        }
                        .frame(width: iconSize, height: iconSize)
                        .padding(.all)
                        .alert(isPresented: $camOfflineAlert) {
                            //Alert(title: Text("Rishi's Device not found!"), message: Text("Please switch Wi-Fi to Oilix Cam Demo"), dismissButton: .default(Text("dismiss")))
                            Alert(title: Text(deviceName+" not found!"), message: Text("Please switch Wi-Fi to "+accessPointName), primaryButton: .default(Text("Go to Settings"), action: {
                                if let url = URL(string:UIApplication.openSettingsURLString) {
                                    if UIApplication.shared.canOpenURL(url) {
                                       let url =  UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    }
                                }
                            }), secondaryButton: .destructive(Text("Cancel")))
                        }
                    }
                    Spacer()
                    Button{
                        //print("cross")
                        isPresented=false
                    }label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(width: iconSize, height: iconSize)
                    .padding(.all)
                }
                .padding(.all)
                /*
                 if(images.count > 0){
                 Image(uiImage: images[previewN])
                 .resizable()
                 //.foregroundColor(lGrey2)
                 .frame(width:350,height: 300)
                 HStack{
                 Button{
                 if(previewN-1>=0){
                 previewN-=1
                 }
                 //print($notes[previewN])
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
                 */
                /*
                 Text("location status: \(locationManager.statusString)")
                 HStack {
                 Text("latitude: \(userLatitude)")
                 Text("longitude: \(userLongitude)")
                 }
                 */
                Spacer()
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:400, height:300)
                    .onReceive(imageLoader.didChange) { data in
                        let imagen = UIImage(data: data)
                        if(imagen != nil)
                        {
                            self.image=imagen!
                            //images.append(imagen!)
                            var teststring = "\(userLatitude),\(userLongitude)"
                            //locations.append(teststring)
                            //notes.append("\(Int.random(in: 1...100))")
                            //times.append(Date())
                            samples.add(image: imagen!, location: teststring, times: Date())
                            AudioServicesPlaySystemSound(1108)
                            shutter=true
                            progressing=false
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                                shutter=false
                            }
                        }
                        else
                        {
                            self.image=UIImage()
                        }
                        //self.image = UIImage(data: data) ?? UIImage()
                    }
                Spacer()
                /*
                 Button("connection test")
                 {
                 
                 
                 }
                 .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                 .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                 .frame(width:220,height:60)
                 .foregroundColor(.white)
                 .background(.blue)
                 .cornerRadius(35)
                 */
                ZStack{
                    if(samples.count>0)
                    {
                        HStack{
                            ZStack{
                                Image(uiImage: samples.samples[0].image)
                                    .resizable()
                                    .scaledToFill()
                                    //.aspectRatio(contentMode: .fill)
                                    .frame(width:60, height:60)
                                    .clipped()
                                    .cornerRadius(4)
                                ZStack(){
                                    Capsule()
                                        //.foregroundColor(.red)
                                        .fill(Color.red)
                                        .frame(width: 25+CGFloat(7*(samples.count / 10)), height: 25)
                                    Text("\(samples.count)")
                                                .foregroundColor(.white)
                                                //.padding(.all,20)
                                }
                                .frame(width: 80, height: 80, alignment: .topTrailing)
                            }
                            .padding(.all,40)
                            Spacer()
                        }
                    }
                    else{
                        HStack{
                            ZStack{
                                Color.black
                                    //.resizable()
                                    .scaledToFill()
                                    //.aspectRatio(contentMode: .fill)
                                    .frame(width:60, height:60)
                                    .clipped()
                                ZStack(){
                                    Capsule()
                                        //.foregroundColor(.red)
                                        .fill(Color.black)
                                        .frame(width: 25+CGFloat(7*(samples.count / 10)), height: 25)
                                    //Text("\(images.count)")
                                                //.foregroundColor(.white)
                                                //.padding(.all,20)
                                }
                                .frame(width: 80, height: 80, alignment: .topTrailing)
                            }
                            .padding(.all,40)
                            Spacer()
                        }

                    }
                    Circle()
                        .stroke(lineWidth: 4)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .onAppear {
                            active=true
                            chkStat()
                        }
                        .onDisappear {
                            active=false
                        }
                    if(progressing)
                    {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2.7)
                    }
                    else{
                        Button//("capture")
                        {
                            if(camStat){
                                imageLoader.res()
                            }
                            else{
                                camOfflineAlert=true
                            }
                            progressing=true
                            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                progressing=false
                            }
                            /*
                             let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                             guard let data = data else { return }
                             DispatchQueue.main.async {
                             data2 = data
                             print(data)
                             }
                             }
                             task.resume()
                             let imagen = UIImage(data: data2)
                             if(imagen != nil){
                             images.append(imagen as! UIImage)
                             }
                             else{
                             print("imagen is nil")
                             print(data2)
                             }
                             */
                        }label: {
                            Image(systemName: "camera.circle.fill")
                                .resizable()
                                .foregroundColor(.white)
                                .aspectRatio(contentMode: .fit)
                        }
                        //.font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                        .frame(width:100,height:100)
                        //.foregroundColor(.white)
                        //.background(.blue)
                        //.cornerRadius(35)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        //.background(Color.black)
        //.ignoresSafeArea()
        .overlay {
            if(shutter){
                Color.black
            }
        }
    }
    
    func chkStat(){
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            //print("checking")
            
            /*
             let manager = Alamofire.NetworkReachabilityManager(host:"192.168.2.12")
             //let manager = Alamofire.NetworkReachabilityManager(host:"wateroil.itongue.cn")
             //let manager = Alamofire.NetworkReachabilityManager(host:"119.45.163.114")
             manager?.startListening { status in
             switch status {
             case .notReachable :
             print("not reachable")
             case .reachable(.cellular) :
             print("cellular")
             case .reachable(.ethernetOrWiFi) :
             print("ethernetOrWiFi")
             default :
             print("unknown")
             }
             }
             */
            
            
            //let conf=URLSessionConfiguration.default
            //conf.timeoutIntervalForRequest=1
            //let ses=Alamofire.Session(configuration:conf)
            
            
            //let url=URL(string:"http://192.168.2.12:8080/stat")!
            let url=URL(string: cameraURL+"stat")!
            AF.request(url, method: .get)
            {
                //(urlRequest: inout URLRequest) in
                urlRequest in
                urlRequest.timeoutInterval=1
            }
            //.validate(statusCode: 200 ..< 299)
            .response{
                response in
                switch(response.result){
                case .success:
                    //print("connection success")
                    camStat=true
                    break
                case .failure(let error):
                    //print(error)
                    //if(error._code==NSURLErrorTimedOut){
                    //    print("timeout")
                    //}
                    camStat=false
                    break
                }
            }
            
            //if(locationManager.statusString=="authorizedWhenInUse" || locationManager.statusString=="authorizedAlways"){
            if(locationManager.locationStatus == .authorizedWhenInUse || locationManager.locationStatus == .authorizedAlways){
                gpsStat=true
            }
            else{
                gpsStat=false
            }
            
            
            
            if(active){
                chkStat()
            }
        }
    }
}

/*
 struct CameraView_Previews: PreviewProvider {
 static var previews: some View {
 CameraView()
 }
 }
 */
