//
//  RegView.swift
//  Oilix
//
//  Created by Guo, Congyu on 3/24/22.
//

import SwiftUI
import Alamofire

struct RegView: View {
    @State var username:String=""
    @State var password:String=""
    @State var name:String=""
    @State var email:String=""
    @State var showAlert:Bool=false
    @State var alertMsg="Unexpected error"
    @Binding var reg : Bool
    var body: some View {
        VStack{
            NavigationView{
                Form{
                    Section(header:Text("Login info")){
                        TextField("Username", text:$username)
                            .autocapitalization(UITextAutocapitalizationType.none)
                            .disableAutocorrection(true)
                        SecureField("Password", text:$password)
                            //.autocapitalization(UITextAutocapitalizationType.none)
                    }
                    Section(header:Text("Personal info")){
                        TextField("Your name(Optional)", text:$name)
                            .disableAutocorrection(true)
                        TextField("E-mail(Optional)", text:$email)
                            .autocapitalization(UITextAutocapitalizationType.none)
                            .disableAutocorrection(true)
                    }
                    Section(){
                        Button(action:{
                            //let url=URL(string:"https://wateroil.itongue.cn/register")!
                            let url=URL(string: serverURL+"register")!
                            //let url=URL(string:"http://47.100.22.28/register")!
                            let parameters=["username":username,"password":password,"email":email,"name":name]
                            struct RegResponse: Codable {
                                var status: Int
                                var msg: String
                            }
                            var j1:RegResponse=RegResponse(status: 9, msg: "")
                            
                            AF.request(url, method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder(destination: .httpBody), headers: nil)
                                .validate(statusCode: 200 ..< 299)
                                .responseJSON { AFdata in
                                    do {
                                        
                                        if(AFdata.data==nil){
                                            print("AFdata.data is nil")
                                            return
                                        }
                                        
                                        print(String(decoding:AFdata.data!, as: UTF8.self))
                                        guard let jsonObject = try JSONSerialization.jsonObject(with: AFdata.data!) as? [String: Any] else {//Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
                                            print("Error: Cannot convert data to JSON object")
                                            return
                                        }
                                        guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                                            print("Error: Cannot convert JSON object to Pretty JSON data")
                                            return
                                        }
                                        j1 =  try JSONDecoder().decode(RegResponse.self, from: prettyJsonData)
                                        print(j1.msg)
                                    } catch {
                                        print("Error: Trying to convert JSON data to string")
                                        //showsAlert=true
                                        self.showAlert=true
                                        return
                                    }
                                    //showsAlert=false
                                    //print("logged")
                                    alertMsg=j1.msg
                                    self.showAlert=true
                                    //let defaults = UserDefaults()
                                    //self.err=false
                                }
                            
                            
                            
                        },
                               label:{Text("Sign up").foregroundColor(.blue)}
                        )
                            .alert(isPresented: ($showAlert)) {
                                Alert(
                                    title: Text("Sign up"),
                                    message: Text(alertMsg)
                                )
                            }
                        Button(action:{
                            reg=false
                        },
                               label:{Text("Back").foregroundColor(.red)}
                        )
                    }
                }.navigationTitle("New account")
            }
        }
    }
}
/*
struct RegView_Previews: PreviewProvider {
    static var previews: some View {
        RegView()
    }
}
*/
