import Foundation
import Alamofire

class Session: ObservableObject {
    @Published var isLoggedIn = false
    @Published var showAlert = false
    @Published var loading = false
    @Published var msg = ""
    @Published var isAdmin = false
    @Published var displayName = ""
    @Published var email = ""
    @Published private(set) var isAccountActionPending = false
    @Published var access = ""
    @Published var refresh = ""
    @Published var disperse: Bool { didSet { defaults.set(disperse, forKey: "disperse") } }
    @Published var deleteConfirm: Bool { didSet { defaults.set(deleteConfirm, forKey: "deleteConfirm") } }
    var name = ""
    var psw = ""
    private let network: Alamofire.Session
    private let defaults: UserDefaults

    init(network: Alamofire.Session = .default, defaults: UserDefaults = .standard) {
        self.network = network
        self.defaults = defaults
        disperse = defaults.object(forKey: "disperse") as? Bool ?? true
        deleteConfirm = defaults.object(forKey: "deleteConfirm") as? Bool ?? true
    }

    func login(asAdmin: Bool = false) {
        loading = true
        showAlert = false
        network.request(serverURL + (asAdmin ? "adminlogin" : "login"), method: .post,
                        parameters: ["username": name, "password": psw],
                        encoder: URLEncodedFormParameterEncoder(destination: .httpBody)) { $0.timeoutInterval = 20 }
            .validate(statusCode: 200..<300)
            .responseDecodable(of: AccountActionResponse.self) { response in
                self.loading = false
                switch response.result {
                case .success(let result):
                    guard result.status == 0 else { self.fail(result.msg); return }
                    self.isAdmin = asAdmin
                    self.displayName = result.meta?.name ?? ""
                    self.email = result.meta?.email ?? ""
                    self.name = result.meta?.username ?? self.name
                    self.defaults.set(self.name, forKey: "username")
                    self.defaults.set(asAdmin, forKey: "isAdmin")
                    // Passwords are never persisted in preferences or logged.
                    self.defaults.removeObject(forKey: "password")
                    self.psw = ""
                    self.isLoggedIn = true
                case .failure:
                    self.fail("Sign in could not be completed. Check your connection and try again.")
                }
            }
    }

    func logout(completed: ((Bool, String) -> Void)? = nil) {
        endAccount(path: "logout", method: .get, completed: completed)
    }

    func deleteUser(completed: ((Bool, String) -> Void)? = nil) {
        endAccount(path: "deleteuser", method: .post, completed: completed)
    }

    private func endAccount(path: String, method: HTTPMethod, completed: ((Bool, String) -> Void)?) {
        guard !isAccountActionPending else { return }
        isAccountActionPending = true
        network.request(serverURL + path, method: method, encoding: JSONEncoding.default) { $0.timeoutInterval = 20 }
            .validate(statusCode: 200..<300)
            .responseDecodable(of: AccountActionResponse.self) { response in
                self.isAccountActionPending = false
                switch response.result {
                case .success(let result):
                    guard result.status == 0 else { completed?(false, result.msg); return }
                    self.name = ""
                    self.psw = ""
                    self.isAdmin = false
                    self.displayName = ""
                    self.email = ""
                    self.showAlert = false
                    self.defaults.removeObject(forKey: "password")
                    self.isLoggedIn = false
                    completed?(true, result.msg)
                case .failure:
                    let message = path == "deleteuser"
                        ? "Account deletion could not be confirmed. Check your connection before retrying."
                        : "Sign out could not be completed. Check your connection and try again."
                    completed?(false, message)
                }
            }
    }

    func refreshProfile(completed: ((Bool, String) -> Void)? = nil) {
        struct ProfileResponse: Decodable {
            let status: Int
            let msg: Profile
            struct Profile: Decodable { let username: String; let name: String; let email: String }
        }
        network.request(serverURL + "user", method: .get) { $0.timeoutInterval = 20 }
            .validate(statusCode: 200..<300)
            .responseData { response in
                guard case .success(let data) = response.result else {
                    completed?(false, "Profile could not be refreshed. Check your connection and try again."); return
                }
                let decoder = JSONDecoder()
                if let failure = try? decoder.decode(AccountActionResponse.self, from: data), failure.status != 0 {
                    completed?(false, failure.msg); return
                }
                guard let result = try? decoder.decode(ProfileResponse.self, from: data), result.status == 0 else {
                    completed?(false, "Profile could not be read. Please try again."); return
                }
                self.name = result.msg.username
                self.displayName = result.msg.name
                self.email = result.msg.email
                completed?(true, "Profile refreshed.")
            }
    }

    func updateProfile(displayName: String, email: String, completed: @escaping (Bool, String) -> Void) {
        network.request(serverURL + "user", method: .post, parameters: ["name": displayName, "email": email],
                        encoder: URLEncodedFormParameterEncoder(destination: .httpBody)) { $0.timeoutInterval = 20 }
            .validate(statusCode: 200..<300)
            .responseDecodable(of: AccountActionResponse.self) { response in
                switch response.result {
                case .success(let result):
                    guard result.status == 0 else { completed(false, result.msg); return }
                    self.displayName = result.meta?.name ?? displayName
                    self.email = result.meta?.email ?? email
                    completed(true, result.msg)
                case .failure:
                    completed(false, "Profile could not be saved. Check your connection and try again.")
                }
            }
    }

    private func fail(_ message: String) { msg = message; showAlert = true }
}
