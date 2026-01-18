//
//  SettingView.swift
//  Oilix
//
//  Created by Guo, Congyu on 12/6/21.
//

import SwiftUI
import Alamofire

struct SettingView: View {
    @StateObject var se:Session
    @State private var camDisconnectAlert=false
    @State private var deleteUserAlert=false
    var body: some View {
        VStack{
            NavigationView{
                Form{
                    Section(header:Text("PROFILE")){
                        HStack{
                            Text("Username")
                            Spacer()
                            Text(se.name).foregroundColor(.gray)
                        }
                        
                        //Text(se.name)
                        //Text(se.access)
                        //Text(se.refresh)
                    }
                    Section(header:Text("PREFERENCE")){
                        Toggle(isOn: $se.disperse) {
                            Text("Disperse")
                        }
                        Toggle(isOn: $se.deleteConfirm) {
                            Text("Confirm before delete")
                        }
                    }
                    Section(){
                        Button(action:{
                            deleteUserAlert=true
                        },label:{Text("Delete Account").foregroundColor(.red)})
                        .alert(isPresented: $deleteUserAlert) {
                            Alert(title: Text("Caution"), message: Text("Once you delete your account, there's no getting it back. Are you sure?"), primaryButton: .destructive(Text("Confirm"), action: {
                                //print("ellipsis1")
                                se.deleteUser()
                            }), secondaryButton: .default(Text("Cancel")))
                            
                            
                        }
                        Button(action:{
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
                                    //isLoggedIn = false
                                    se.logout()
                                    break
                                }
                            }
                        },
                               label:{Text("Sign out").foregroundColor(.red)}
                        )
                            .alert(isPresented: ($camDisconnectAlert)) {
                                Alert(
                                    title: Text("Error"),
                                    message: Text("Disconnect "+deviceName+" before logout.")
                                )
                            }
                    }
                }.navigationTitle("Settings")
            }
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        let se=Session()
        SettingView(se:se)
    }
}
