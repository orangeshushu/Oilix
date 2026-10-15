import SwiftUI
import Alamofire
import UIKit

struct LoginView: View {
    @ObservedObject var se: Session
    @State private var name = ""
    @State private var password = ""
    @State private var loginMode = 0
    @State private var registration = false
    @State private var resetPassword = false
    @State private var instructions = false
    @State private var cameraAlert = false
    @State private var passwordVisible = false
    @FocusState private var focusedField: Field?
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .subheadline) private var fieldLabelWidth = 88

    private enum Field: Hashable { case username, password }

    private var canSignIn: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    var body: some View {
        OilixNavigation {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(spacing: 12) {
                            HStack(spacing: 24) {
                                Image("mu").resizable().scaledToFit().frame(width: 72, height: 84)
                                Image("msu").resizable().scaledToFit().frame(width: 72, height: 84)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("University of Missouri and Missouri State University")
                            .accessibilityIdentifier("login.logos")
                            VStack(spacing: 4) {
                                Text("Oilix").font(.title2.bold())
                                    .accessibilityIdentifier("login.brandTitle")
                                Text("Oil Analysis Tool and Information Exchange")
                                    .font(.caption.weight(.medium))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityIdentifier("login.brandSubtitle")
                            }
                            .foregroundColor(.black)
                        }.multilineTextAlignment(.center).frame(maxWidth: .infinity)
                        LoginAccountPicker(selection: $loginMode)
                            .frame(height: 48)
                        VStack(spacing: 0) {
                            credentialRow("Username") {
                                HStack(spacing: 0) {
                                    TextField("Required", text: $name)
                                        .textContentType(.username)
                                        .textInputAutocapitalization(.never).disableAutocorrection(true)
                                        .submitLabel(.next).focused($focusedField, equals: .username)
                                        .onSubmit { focusedField = .password }
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .accessibilityLabel("Username")
                                        .accessibilityIdentifier("login.username")
                                    if name.isEmpty {
                                        Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
                                    } else {
                                        Button { name = ""; focusedField = .username } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 16)).foregroundColor(.secondary)
                                                .frame(width: 44, height: 44)
                                        }.buttonStyle(.plain).accessibilityLabel("Clear username")
                                            .accessibilityIdentifier("login.username.clear")
                                    }
                                }
                            }
                            .id("login.usernameRow")
                            Divider().padding(.horizontal, 16)
                            credentialRow("Password") {
                                HStack(spacing: 0) {
                                    Group {
                                        if passwordVisible { TextField("Required", text: $password) }
                                        else { SecureField("Required", text: $password) }
                                    }
                                    .textContentType(.password)
                                    .textInputAutocapitalization(.never).disableAutocorrection(true)
                                    .submitLabel(.go).focused($focusedField, equals: .password)
                                    .onSubmit { if canSignIn && !se.loading { signIn() } }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .accessibilityLabel("Password")
                                    .accessibilityIdentifier("login.password")
                                    Button(action: togglePasswordVisibility) {
                                        Image(systemName: passwordVisible ? "eye.slash" : "eye")
                                            .font(.system(size: 18)).frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain).foregroundColor(.secondary)
                                    .accessibilityLabel(passwordVisible ? "Hide password" : "Show password")
                                    .accessibilityIdentifier("login.password.visibility")
                                }
                            }
                            .id("login.passwordRow")
                        }
                        .id("login.credentials")
                        .textFieldStyle(.plain)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                            focusedField == nil ? Color(uiColor: .separator).opacity(0.3) : Color.accentColor,
                            lineWidth: 1))
                        Button(action: signIn) {
                            HStack(spacing: 12) {
                                if se.loading { ProgressView().tint(.secondary) }
                                Text(se.loading ? "Signing In..." : loginMode == 0 ? "Sign In" : "Admin Sign In")
                            }
                        }
                        .buttonStyle(PrimaryActionStyle())
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(Color(uiColor: .systemBackground).opacity(0.9)))
                        .disabled(!canSignIn || se.loading)
                        .accessibilityIdentifier("login.signIn")
                        if typeSize.isAccessibilitySize {
                            VStack(spacing: 8) { accountActions }
                        } else {
                            HStack(spacing: 16) { accountActions }
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 20)
                    .frame(maxWidth: 480, alignment: .leading).frame(maxWidth: .infinity)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                    scrollToCredentials(using: proxy)
                }
                .onChange(of: focusedField) { _ in scrollToCredentials(using: proxy) }
                .oilixKeyboardDismissal()
                .background(loginBackground)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { instructions = true } label: { Label("Instructions", systemImage: "book") }
                            .accessibilityIdentifier("login.instructions")
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focusedField = nil }.accessibilityIdentifier("login.keyboardDone")
                    }
                }
            }
        }
        .disabled(se.loading)
        .sheet(isPresented: $registration) { RegView(reg: $registration, onCreated: { name = $0; password = "" }) }
        .sheet(isPresented: $resetPassword) { ResetView(res: $resetPassword, initialUsername: name) }
        .sheet(isPresented: $instructions) { InstructionsView() }
        .alert("Sign In Failed", isPresented: $se.showAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text(se.msg) }
        .alert("Connect to the Internet", isPresented: $cameraAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Disconnect from \(deviceName) and connect to Wi-Fi or cellular data before signing in.")
        }
    }

    private var loginBackground: some View {
        GeometryReader { geometry in
            Image("ol2").resizable().scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(Color.white.opacity(0.5))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func scrollToCredentials(using proxy: ScrollViewProxy) {
        guard let field = focusedField else { return }
        let target = typeSize.isAccessibilitySize
            ? (field == .username ? "login.usernameRow" : "login.passwordRow") : "login.credentials"
        proxy.scrollTo(target, anchor: .center)
    }

    private func credentialRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.weight(.medium))
                    content()
                }
            } else {
                HStack(spacing: 12) {
                    Text(title).font(.subheadline.weight(.medium))
                        .frame(width: fieldLabelWidth, alignment: .leading)
                    content()
                }
            }
        }.padding(.horizontal, 16).padding(.vertical, 6)
    }

    @ViewBuilder
    private var accountActions: some View {
        if loginMode == 0 {
            Button("Create Account") { registration = true }
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        Button("Forgot Password?") { resetPassword = true }
            .frame(maxWidth: .infinity, minHeight: 44)
    }

    private func togglePasswordVisibility() {
        let wasEditing = focusedField == .password
        passwordVisible.toggle()
        if wasEditing { DispatchQueue.main.async { focusedField = .password } }
    }

    private func signIn() {
        guard canSignIn && !se.loading else { return }
        focusedField = nil
        se.loading = true
        AF.request(cameraURL + "stat", method: .get) { $0.timeoutInterval = 1 }
            .response { response in
                if case .success = response.result {
                    se.loading = false
                    cameraAlert = true
                } else {
                    se.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    se.psw = password
                    se.login(asAdmin: loginMode == 1)
                }
            }
    }
}

private struct LoginAccountPicker: UIViewRepresentable {
    @Binding var selection: Int
    @Environment(\.isEnabled) private var isEnabled

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = LoginAccountSegmentedControl(items: ["User", "Admin"])
        control.accessibilityIdentifier = "login.accountType"
        control.accessibilityLabel = "Account type"
        control.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ control: UISegmentedControl, context: Context) {
        control.selectedSegmentIndex = selection
        control.isEnabled = isEnabled
        control.backgroundColor = .white
        control.selectedSegmentTintColor = UIColor(red: 0.03, green: 0.28, blue: 0.60, alpha: 1)
        let font = UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(for: .systemFont(ofSize: 15, weight: .semibold), maximumPointSize: 20)
        control.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: font], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: font], for: .selected)
        control.layer.borderWidth = 1
        control.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        control.layer.cornerRadius = 8
    }

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection) }

    final class Coordinator: NSObject {
        private let selection: Binding<Int>
        init(selection: Binding<Int>) { self.selection = selection }

        @objc func changed(_ control: UISegmentedControl) {
            selection.wrappedValue = control.selectedSegmentIndex
        }
    }
}

private final class LoginAccountSegmentedControl: UISegmentedControl {
    override var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width, height: 48)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: super.sizeThatFits(size).width, height: 48)
    }
}
