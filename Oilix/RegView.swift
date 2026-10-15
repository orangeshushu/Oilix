import SwiftUI
import Alamofire

struct RegView: View {
    @Binding var reg: Bool
    var onCreated: (String) -> Void = { _ in }
    @State private var username = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var name = ""
    @State private var email = ""
    @State private var submitting = false
    @State private var error: String?
    @State private var success = false
    @State private var discard = false

    private var valid: Bool {
        AccountValidation.usernameIsValid(username) && AccountValidation.newPasswordIsValid(password)
            && password == confirmation && AccountValidation.emailIsValid(email, optional: true)
            && AccountValidation.nameIsValid(name)
    }

    private var hasDraft: Bool {
        !username.isEmpty || !password.isEmpty || !confirmation.isEmpty || !name.isEmpty || !email.isEmpty
    }

    var body: some View {
        OilixNavigation {
            Form {
                Section(header: Text("Account")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username").font(.subheadline)
                        TextField("Username", text: $username).textContentType(.username)
                            .textInputAutocapitalization(.never).disableAutocorrection(true)
                            .accessibilityIdentifier("register.username")
                    }
                    PasswordInput(title: "Password", text: $password, newPassword: true, identifier: "register.password")
                    PasswordInput(title: "Confirm Password", text: $confirmation, newPassword: true, identifier: "register.confirmation")
                    if !password.isEmpty && !AccountValidation.newPasswordIsValid(password) {
                        FormMessage(text: "Use 8 to 255 characters for your password.")
                    }
                    if !confirmation.isEmpty && confirmation != password {
                        FormMessage(text: "Passwords do not match.")
                    }
                }
                Section(header: Text("Profile")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name (optional)").font(.subheadline)
                        TextField("Name", text: $name).textContentType(.name)
                            .accessibilityIdentifier("register.name")
                        if !AccountValidation.nameIsValid(name) { FormMessage(text: "Use up to 50 characters for your name.") }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email (optional)").font(.subheadline)
                        TextField("Email", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).disableAutocorrection(true)
                            .accessibilityIdentifier("register.email")
                    }
                    if !AccountValidation.emailIsValid(email, optional: true) {
                        FormMessage(text: "Enter a valid email address.")
                    }
                }
                Section {
                    if let error = error { FormMessage(text: error) }
                    Button(action: createAccount) {
                        HStack {
                            if submitting { ProgressView() }
                            Text(submitting ? "Creating Account..." : "Create Account").font(.headline)
                        }.frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .disabled(!valid || submitting)
                    .accessibilityIdentifier("register.submit")
                }
            }
            .disabled(submitting)
            .oilixKeyboardDismissal()
            .navigationTitle("Create Account").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                        .accessibilityIdentifier("register.keyboardDone")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { if hasDraft { discard = true } else { reg = false } }
                        .disabled(submitting)
                }
            }
        }
        .interactiveDismissDisabled(hasDraft || submitting)
        .alert("Discard this account form?", isPresented: $discard) {
            Button("Discard", role: .destructive) { reg = false }
            Button("Keep Editing", role: .cancel) { }
        }
        .alert("Account Created", isPresented: $success) {
            Button("Sign In") { onCreated(username.trimmingCharacters(in: .whitespacesAndNewlines)); reg = false }
        } message: { Text("Your account is ready. Sign in to start sampling.") }
    }

    private func createAccount() {
        guard valid && !submitting else { return }
        submitting = true
        error = nil
        let parameters = ["username": username.trimmingCharacters(in: .whitespacesAndNewlines),
                          "password": password, "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                          "email": email.trimmingCharacters(in: .whitespacesAndNewlines)]
        AF.request(serverURL + "register", method: .post, parameters: parameters,
                   encoder: URLEncodedFormParameterEncoder(destination: .httpBody)) { $0.timeoutInterval = 20 }
            .validate(statusCode: 200..<300)
            .responseDecodable(of: AccountActionResponse.self) { response in
                submitting = false
                switch response.result {
                case .success(let result):
                    if result.status == 0 { success = true } else { error = result.msg }
                case .failure:
                    error = "Account creation could not be confirmed. Try signing in before creating it again."
                }
            }
    }
}
