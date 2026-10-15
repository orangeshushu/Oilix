import SwiftUI

enum AccountValidation {
    static func emailIsValid(_ email: String, optional: Bool = false) -> Bool {
        let value = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return optional }
        return value.count <= 255 && value.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#,
                                                options: .regularExpression) != nil
    }

    static func usernameIsValid(_ username: String) -> Bool {
        let value = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !value.isEmpty && value.count <= 255
    }

    static func newPasswordIsValid(_ password: String) -> Bool {
        password.count >= 8 && password.count <= 255 && !password.allSatisfy(\.isWhitespace)
    }

    static func nameIsValid(_ name: String) -> Bool { name.count <= 50 }
}

struct AccountActionResponse: Decodable {
    let status: Int
    let msg: String
    let meta: Metadata?
    struct Metadata: Decodable {
        let username: String?
        let name: String?
        let email: String?
    }
}

struct PasswordInput: View {
    let title: String
    @Binding var text: String
    var newPassword = false
    var identifier: String
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline)
            HStack(spacing: 12) {
                Group {
                    if revealed { TextField(title, text: $text) }
                    else { SecureField(title, text: $text) }
                }
                .textContentType(newPassword ? .newPassword : .password)
                .textInputAutocapitalization(.never).disableAutocorrection(true)
                .accessibilityIdentifier(identifier)
                Button { revealed.toggle() } label: {
                    Image(systemName: revealed ? "eye.slash" : "eye")
                        .font(.system(size: 18)).frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier(identifier + ".visibility")
                .accessibilityLabel(revealed ? "Hide \(title.lowercased())" : "Show \(title.lowercased())")
            }
        }
    }
}

struct FormMessage: View {
    let text: String
    var body: some View {
        Label(text, systemImage: "exclamationmark.circle")
            .font(.subheadline).foregroundColor(.red)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
    }
}
