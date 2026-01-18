//
//  ResetView.swift
//  Oilix
//
//  Created by Guo, Congyu on 8/18/22.
//

import SwiftUI
import Alamofire

struct ResetView: View {
    @State var username:String=""
    @State var password:String=""
    @State var password2:String=""
    @State var email:String=""
    @State var showAlert:Bool=false
    @State var alertMsg="Unexpected error"
    @Binding var res : Bool
    var body: some View {
        VStack{
            NavigationView{
                Form{
                    Section(header:Text("Account info")){
                        TextField("Username", text:$username)
                            .autocapitalization(UITextAutocapitalizationType.none)
                            .disableAutocorrection(true)
                        TextField("E-mail(associated with account)", text:$email)
                            .autocapitalization(UITextAutocapitalizationType.none)
                            .disableAutocorrection(true)
                    }
                    Section(header:Text("New password")){
                        SecureField("Choose password", text:$password)
                        SecureField("Re-enter new password", text:$password2)
                    }
                    Section(){
                        Button(action:{
                            if(password==password2){
                                let url=URL(string: serverURL+"resetpassword")!
                                let parameters=["username":username,"password":password,"email":email]
                                struct ResetResponse: Codable {
                                    var status: Int
                                    var msg: String
                                    struct ResetMeta: Codable{
                                        var attempted_username: String
                                    }
                                    var meta: ResetMeta
                                }
                                var j1:ResetResponse?
                                
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
                                            j1 =  try JSONDecoder().decode(ResetResponse.self, from: prettyJsonData)
                                            print(j1!.msg)////////////
                                        } catch {
                                            print("Error: Trying to convert JSON data to string")
                                            alertMsg="JSON decode error."
                                            self.showAlert=true
                                            return
                                        }
                                        alertMsg=j1!.msg
                                        self.showAlert=true
                                    }
                            }else{
                                alertMsg="Password and re-entered password must match."
                                self.showAlert=true
                            }
                        },
                               label:{Text("Reset").foregroundColor(.blue)}
                        )
                        .alert(isPresented: ($showAlert)) {
                            Alert(
                                title: Text("Password reset"),
                                message: Text(alertMsg)
                            )
                        }
                        Button(action:{
                            res=false
                        },
                               label:{Text("Back").foregroundColor(.red)}
                        )
                    }
                }.navigationTitle("Reset password")
            }
        }
    }
}
/*
struct ResetView_Previews: PreviewProvider {
    static var previews: some View {
        ResetView()
    }
}
*/
