//
//  UserListView.swift
//  Oilix
//
//  Created by OpenAI Codex on 4/29/26.
//

import SwiftUI
import Alamofire

struct UserSummary: Identifiable {
    let id: Int
    let username: String
    let name: String
    let email: String
    let role: String
    let photoCount: Int
}

struct UserListView: View {
    @State private var users = [UserSummary]()
    @State private var loading = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var body: some View {
        List(users) { user in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(user.username)
                        .font(.headline)
                    Spacer()
                    Text(user.role.capitalized)
                        .font(.subheadline)
                        .foregroundColor(user.role.lowercased() == "admin" ? .blue : .gray)
                }
                if !user.name.isEmpty {
                    Text(user.name)
                        .font(.subheadline)
                }
                if !user.email.isEmpty {
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text("\(user.photoCount) photos")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .overlay {
            if loading {
                ProgressView("Loading users...")
            } else if users.isEmpty {
                Text("No users available")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Registered Users")
        .onAppear {
            loadUsers()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Users"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func loadUsers() {
        loading = true
        let url = URL(string: serverURL+"userlist")!
        
        AF.request(url, method: .post, parameters: [String: String](), encoder: URLEncodedFormParameterEncoder(destination: .httpBody), headers: nil)
            .validate(statusCode: 200 ..< 299)
            .responseJSON { AFdata in
                loading = false
                guard let data = AFdata.data else {
                    alertMessage = "Network error. Please try again."
                    showAlert = true
                    return
                }
                
                do {
                    guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        alertMessage = "Unable to read server response."
                        showAlert = true
                        return
                    }
                    
                    let status = jsonObject["status"] as? Int ?? 9
                    if status != 0 {
                        alertMessage = jsonObject["msg"] as? String ?? "Unable to load users."
                        showAlert = true
                        return
                    }
                    
                    guard let records = jsonObject["msg"] as? [String: Any] else {
                        users = []
                        return
                    }
                    
                    users = records.values.compactMap { value in
                        guard let record = value as? [String: Any],
                              let id = record["id"] as? Int,
                              let username = record["username"] as? String,
                              let name = record["name"] as? String,
                              let email = record["email"] as? String,
                              let role = record["role"] as? String,
                              let photoCount = record["photo_count"] as? Int else {
                            return nil
                        }
                        
                        return UserSummary(
                            id: id,
                            username: username,
                            name: name,
                            email: email,
                            role: role,
                            photoCount: photoCount
                        )
                    }
                    .sorted { $0.id < $1.id }
                } catch {
                    alertMessage = "Unable to read server response."
                    showAlert = true
                }
            }
    }
}

struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserListView()
        }
    }
}
