//
//  LoginView.swift
//  Oilix
//
//  Created by Guo, Congyu on 11/23/21.
//

import SwiftUI
import Alamofire

//let lGrey=Color(red:239.0/255.0, green:243.0/255.0, blue:244.0/255.0, opacity: 100.0/255.0)

struct LoginView: View {
    //@State var showsAlert = false
    @State private var name=""
    @State private var psw=""
    @State var reg=false
    @State var res=false
    @State var dis=false
    @State private var loginMode=0
    //@State var loading=false
    @State private var camDisconnectAlert=false
    @StateObject var se:Session
    //@State var t1=false
    private var canSignIn: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !psw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var body: some View {
        GeometryReader{ geometry in
            ZStack(alignment: .center) {
                
                ZStack
                {
                    
                    
                    Image("ol2")
                        .resizable()
                    //.scaledToFit()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                        .frame(width:geometry.size.width)
                     
                    //Text("login")
                    HStack{
                        
                    Spacer()
                    VStack{
                        Spacer()/*
                        Image("usgs")
                            .resizable()
                            .scaledToFit()
                            .frame(height:geometry.size.width/4.5)
                            .foregroundColor(.gray)*/
                        //Image(systemName: "person.crop.circle.fill")
                        HStack{
                            Image("mu")
                                .resizable()
                                .scaledToFit()
                                .frame(height:geometry.size.width/3.5)
                                .foregroundColor(.gray)
                            Image("msu")
                                .resizable()
                                .scaledToFit()
                                .frame(height:geometry.size.width/3.5)
                                .foregroundColor(.gray)
                        }
                        Text("Oilix")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            //.padding(.top, 30)
                        Text("Oil Analysis Tool and Information Exchange")
                            .font(.system(size: 15))
                            //.padding(.bottom, 10)
                        Picker("Login type", selection: $loginMode) {
                            Text("User").tag(0)
                            Text("Admin").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: geometry.size.width*0.8)
                        .padding(.top, 8)
                        VStack{
                            //Text("User Name").fontWeight(.bold)
                            TextField("Username",text:$name)
                                .padding()
                                .foregroundColor(.black)
                                .background(lGrey)
                                .cornerRadius(10)
                                .autocapitalization(UITextAutocapitalizationType.none)
                                .disableAutocorrection(true)
                                .submitLabel(.continue)
                            //Text("Password").fontWeight(.bold)
                            SecureField("Password",text:$psw)
                                .padding()
                                .foregroundColor(.black)
                                .background(lGrey)
                                .cornerRadius(10)
                                .submitLabel(.done)
                            //Button(){                            print("Hello world!")                        }
                        }.frame(width: geometry.size.width*0.8, height: 200.0)//////////////
                        
                        
                        Button {
                            se.loading=true
                            let camUrl=URL(string: cameraURL+"stat")!
                            AF.request(camUrl, method: .get)//try to connect with OilixCam first
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
                                case .failure(_):
                                    se.name=name
                                    se.psw=psw
                                    se.login(asAdmin: loginMode == 1)
                                    break
                                }
                            }
                            
                            /*
                             if !res
                             {
                             showsAlert=true
                             print("showsAlert=true")
                             }
                             else{
                             showsAlert=false
                             print("showsAlert=false")
                             }
                            */
                            //print("err:")
                            //print(se.showAlert)
                        } label: {
                            Text(loginMode == 0 ? "Sign In" : "Admin Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width:geometry.size.width*0.6,height:60)
                                .background(canSignIn ? Color.blue : Color.gray)
                                .cornerRadius(35)
                                .contentShape(Rectangle())
                        }
                        .alert(isPresented: ($se.showAlert)) {
                            Alert(
                                title: Text("Error"),
                                //message: Text("Sign in failed")
                                message: Text(se.msg)
                            )
                        }
                        .disabled(!canSignIn)
                        
                        VStack
                        {
                            if loginMode == 0 {
                                HStack{
                                    Text("No account?").font(.system(size:15))
                                /*
                                 Link(destination: URL(string: "https://answers.usgs.gov/")!, label: {
                                 Text("SIGN UP").font(.system(size:15))
                                 }
                                 
                                 )
                                 */
                                    Button("Sign Up"){
                                        reg=true
                                    }
                                    .font(.system(size:15))
                                }
                            }
                            HStack{
                                Button("Forgot Password?"){
                                    res=true
                                }
                                .font(.system(size:15))
                                //Button("test") {se.testLogin()}///////////////////
                            }
                            .alert(isPresented: ($camDisconnectAlert)) {
                                Alert(
                                    title: Text("Error"),
                                    message: Text("Disconnect "+deviceName+" before login.")
                                )
                            }/*
                            Button("Disclaimer"){
                                dis=true
                            }
                            .font(.system(size:15))
                            .alert(isPresented: ($dis)) {
                                Alert(
                                    title: Text("Disclaimer"),
                                    message: Text("This software is preliminary or provisional and is subject to revision. It is being provided to meet the need for timely best science. The software has not received final approval by the U.S. Geological Survey (USGS). No warranty, expressed or implied, is made by the USGS or the U.S. Government as to the functionality of the software and related material nor shall the fact of release constitute any such warranty. The software is provided on the condition that neither the USGS nor the U.S. Government shall be held liable for any damages resulting from the authorized or unauthorized use of the software.")
                                )
                            }*/
                            /*
                             Button("test") {
                             //showsAlert=false
                             //print("testlogin")
                             //se.isLoggedIn=true
                             //t1 = !t1
                             $se.showAlert=true
                             }
                             Button("test2") {
                             //showsAlert=false
                             print($se.showAlert)
                             //se.isLoggedIn=true
                             //t1 = !t1
                             }
                             */
                            /*
                             NavigationLink(destination: tab()) {
                             Text("test2")
                             }
                             */
                        }/*
                        .alert(isPresented: ($camDisconnectAlert)) {
                            Alert(
                                title: Text("Error"),
                                message: Text("Disconnect "+deviceName+" before login.")
                            )
                        }
                        */
                        
                        Spacer()
                        
                    }
                    Spacer()
                }
                }
                .disabled(se.loading)
                .blur(radius: se.loading ? 2 : 0)
                .sheet(isPresented: $reg, content: {
                    RegView(reg:$reg)
                })
                .sheet(isPresented: $res, content: {
                    ResetView(res:$res)
                })
                
                if se.loading{
                    Rectangle()
                        .fill(Color.black).opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    VStack(spacing:48){
                        ProgressView()
                            .scaleEffect(2.0, anchor: .center)
                        Text("Logging in...")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    .frame(width: geometry.size.width*0.6, height: geometry.size.width*0.5, alignment: .center)
                    .background(Color.white)
                    .foregroundColor(Color.primary)
                    .cornerRadius(20)
                }
            }
        }
        
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let se=Session()
        LoginView(se:se)
    }
}
