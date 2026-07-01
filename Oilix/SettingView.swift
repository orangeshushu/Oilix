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
                        HStack{
                            Text("Account type")
                            Spacer()
                            Text(se.isAdmin ? "Admin" : "User").foregroundColor(.gray)
                        }
                        HStack{
                            Text("Name:")
                            Spacer()
                            Text(se.displayName.isEmpty ? "Not set" : se.displayName).foregroundColor(.gray)
                        }
                        HStack{
                            Text("Email:")
                            Spacer()
                            Text(se.email.isEmpty ? "Not set" : se.email).foregroundColor(.gray)
                        }
                        NavigationLink(destination: ProfileEditView(se: se)) {
                            Text("Edit Profile")
                        }
                    }
                    Section(header:Text("PREFERENCE")){
                        Toggle(isOn: $se.disperse) {
                            Text("Disperse")
                        }
                        Toggle(isOn: $se.deleteConfirm) {
                            Text("Confirm before delete")
                        }
                    }
                    if se.isAdmin {
                        Section(header:Text("ADMIN")){
                            NavigationLink(destination: UserListView()) {
                                Text("Registered Users")
                            }
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
                                case .failure(_):
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
                }
                .navigationTitle("Settings")
                .onAppear {
                    se.refreshProfile()
                }
            }
        }
    }
}

struct ProfileEditView: View {
    @ObservedObject var se: Session
    @Environment(\.presentationMode) private var presentationMode
    @State private var profileName = ""
    @State private var profileEmail = ""
    @State private var profileAlert = false
    @State private var profileAlertTitle = "Profile"
    @State private var profileAlertMessage = ""
    @State private var profileSaving = false
    @State private var saveSucceeded = false
    
    var body: some View {
        Form {
            Section(header: Text("PROFILE")) {
                TextField("Name", text:$profileName)
                    .disableAutocorrection(true)
                TextField("Email", text:$profileEmail)
                    .autocapitalization(UITextAutocapitalizationType.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
            }
            Section {
                Button(action:{
                    profileSaving=true
                    se.updateProfile(displayName: profileName, email: profileEmail) { success, message in
                        profileSaving=false
                        saveSucceeded=success
                        profileAlertTitle=success ? "Profile Updated" : "Update Failed"
                        profileAlertMessage=message
                        profileAlert=true
                    }
                },label:{
                    Text(profileSaving ? "Saving..." : "Save Profile")
                })
                .disabled(profileSaving)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            profileName=se.displayName
            profileEmail=se.email
        }
        .alert(isPresented: $profileAlert) {
            Alert(
                title: Text(profileAlertTitle),
                message: Text(profileAlertMessage),
                dismissButton: .default(Text("OK"), action: {
                    if saveSucceeded {
                        presentationMode.wrappedValue.dismiss()
                    }
                })
            )
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        let se=Session()
        SettingView(se:se)
    }
}
