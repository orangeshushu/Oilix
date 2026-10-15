import SwiftUI
import Alamofire

struct ResetView: View {
    @Binding var res: Bool
    var initialUsername = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var email = ""
    @State private var submitting = false
    @State private var error: String?
    @State private var success = false
    @State private var discard = false
    @State private var initialized = false

    private var valid: Bool {
        AccountValidation.usernameIsValid(username) && AccountValidation.emailIsValid(email)
            && AccountValidation.newPasswordIsValid(password) && password == confirmation
    }

    var body: some View {
        OilixNavigation {
            Form {
                Section(header: Text("Account")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username").font(.subheadline)
                        TextField("Username", text: $username).textContentType(.username)
                            .textInputAutocapitalization(.never).disableAutocorrection(true)
                            .accessibilityIdentifier("reset.username")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Account Email").font(.subheadline)
                        TextField("Email", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).disableAutocorrection(true)
                            .accessibilityIdentifier("reset.email")
                    }
                    if !email.isEmpty && !AccountValidation.emailIsValid(email) {
                        FormMessage(text: "Enter a valid email address.")
                    }
                }
                Section(header: Text("New Password")) {
                    PasswordInput(title: "New Password", text: $password, newPassword: true, identifier: "reset.password")
                    PasswordInput(title: "Confirm Password", text: $confirmation, newPassword: true, identifier: "reset.confirmation")
                    if !password.isEmpty && !AccountValidation.newPasswordIsValid(password) {
                        FormMessage(text: "Use 8 to 255 characters for your password.")
                    }
                    if !confirmation.isEmpty && confirmation != password { FormMessage(text: "Passwords do not match.") }
                }
                Section {
                    if let error = error { FormMessage(text: error) }
                    Button(action: resetPassword) {
                        HStack {
                            if submitting { ProgressView() }
                            Text(submitting ? "Resetting Password..." : "Reset Password").font(.headline)
                        }.frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .disabled(!valid || submitting)
                    .accessibilityIdentifier("reset.submit")
                }
            }
            .disabled(submitting)
            .oilixKeyboardDismissal()
            .navigationTitle("Reset Password").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                        .accessibilityIdentifier("reset.keyboardDone")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if !password.isEmpty || !confirmation.isEmpty || !email.isEmpty { discard = true }
                        else { res = false }
                    }.disabled(submitting)
                }
            }
        }
        .onAppear { if !initialized { username = initialUsername; initialized = true } }
        .interactiveDismissDisabled(submitting || !password.isEmpty || !confirmation.isEmpty || !email.isEmpty)
        .alert("Discard password changes?", isPresented: $discard) {
            Button("Discard", role: .destructive) { res = false }
            Button("Keep Editing", role: .cancel) { }
        }
        .alert("Password Updated", isPresented: $success) {
            Button("Sign In") { res = false }
        } message: { Text("Sign in with your new password.") }
    }

    private func resetPassword() {
        guard valid && !submitting else { return }
        error = nil
        submitting = true
        AF.request(serverURL + "resetpassword", method: .post,
                   parameters: ["username": username.trimmingCharacters(in: .whitespacesAndNewlines),
                                "email": email.trimmingCharacters(in: .whitespacesAndNewlines), "password": password],
                   encoder: URLEncodedFormParameterEncoder(destination: .httpBody)) { $0.timeoutInterval = 20 }
            .validate(statusCode: 200..<300)
            .responseDecodable(of: AccountActionResponse.self) { response in
                submitting = false
                switch response.result {
                case .success(let result):
                    if result.status == 0 { success = true } else { error = result.msg }
                case .failure:
                    error = "Password reset could not be confirmed. Try signing in with the new password before retrying."
                }
            }
    }
}
