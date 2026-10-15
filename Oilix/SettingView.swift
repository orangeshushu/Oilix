import SwiftUI
import Alamofire

struct SettingView: View {
    @ObservedObject var se: Session
    var hasPendingSamples = false
    var isSamplingBusy = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var instructions = false
    @State private var editProfile = false
    @State private var deleteUser = false
    @State private var signOut = false
    @State private var checkingConnection = false
    @State private var refreshing = false
    @State private var error: String?
    @State private var profileExpanded = false
    @State private var preferencesExpanded = false
    @State private var accountExpanded = false

    private var busy: Bool { checkingConnection || se.isAccountActionPending || isSamplingBusy }

    var body: some View {
        OilixNavigation {
            Form {
                if let error = error {
                    Section {
                        FormMessage(text: error)
                        Button("Refresh Profile") { refreshProfile() }.disabled(refreshing)
                    }
                }
                Section(header: Text("Profile")) {
                    DisclosureGroup(isExpanded: $profileExpanded) {
                        profileRow("Username", value: se.name)
                        profileRow("Account type", value: se.isAdmin ? "Admin" : "User")
                        profileRow("Name:", value: se.displayName)
                        profileRow("Email:", value: se.email)
                        Button { editProfile = true } label: { Label("Edit Profile", systemImage: "person.crop.circle") }
                            .accessibilityIdentifier("settings.editProfile")
                        if refreshing { ProgressView("Refreshing Profile...") }
                    } label: {
                        Label("Personal Profile", systemImage: "person.crop.circle")
                            .frame(minHeight: 44).oilixTourTarget(.profile)
                    }
                }
                Section(header: Text("Preferences")) {
                    DisclosureGroup(isExpanded: $preferencesExpanded) {
                        Toggle("Separate overlapping map markers", isOn: $se.disperse)
                        Toggle("Confirm before delete", isOn: $se.deleteConfirm)
                    } label: {
                        Label("Map & Deletion", systemImage: "slider.horizontal.3").frame(minHeight: 44)
                    }
                }
                Section(header: Text("Help")) {
                    Button { instructions = true } label: { Label("Instructions", systemImage: "book") }
                        .accessibilityIdentifier("settings.instructions")
                    Link(destination: URL(string: "https://wateroil.web.app")!) {
                        Label("Web Database", systemImage: "arrow.up.right.square")
                    }
                    NavigationLink(destination: AcknowledgementsView()) {
                        Label("Acknowledgements", systemImage: "heart")
                    }.accessibilityIdentifier("settings.acknowledgements")
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion).foregroundColor(.secondary)
                    }
                }
                if se.isAdmin {
                    Section(header: Text("Administration")) {
                        NavigationLink(destination: UserListView()) { Label("Registered Users", systemImage: "person.2") }
                            .accessibilityIdentifier("settings.registeredUsers")
                    }
                }
                Section(header: Text("Account")) {
                    if isSamplingBusy { Label("Finish the current image operation before signing out.", systemImage: "clock") }
                    if checkingConnection || se.isAccountActionPending { ProgressView("Please wait...") }
                    Button { signOut = true } label: { Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") }
                        .disabled(busy).accessibilityIdentifier("settings.signOut")
                    DisclosureGroup(isExpanded: $accountExpanded) {
                        Button(role: .destructive) { deleteUser = true } label: { Label("Delete Account", systemImage: "person.crop.circle.badge.minus") }
                            .disabled(busy)
                    } label: { Label("Account Management", systemImage: "person.badge.shield.checkmark").frame(minHeight: 44) }
                }
            }
            .oilixKeyboardDismissal()
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .onAppear { refreshProfile() }
            .refreshable {
                await withCheckedContinuation { continuation in
                    refreshProfile { continuation.resume() }
                }
            }
        }
        .oilixTourSurface(tab: 3)
        .sheet(isPresented: $instructions) { InstructionsView() }
        .sheet(isPresented: $editProfile) { ProfileEditView(se: se) }
        .confirmationDialog("Sign out?", isPresented: $signOut, titleVisibility: .visible) {
            Button("Sign Out", action: performSignOut)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(hasPendingSamples ? "Your selected, unuploaded images will be discarded. Original photos will be kept." : "You can sign in again at any time.")
        }
        .confirmationDialog("Permanently delete your account?", isPresented: $deleteUser, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                guard !busy else { return }
                error = nil
                se.deleteUser { success, message in if !success { error = message } }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This cannot be undone. Any unuploaded selection will also be discarded. Your original photos will be kept.") }
    }

    @ViewBuilder
    private func profileRow(_ title: String, value: String) -> some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.subheadline).foregroundColor(.secondary)
                profileValue(value)
            }
        } else {
            HStack(alignment: .top, spacing: 16) {
                Text(title).font(.subheadline).foregroundColor(.secondary).fixedSize()
                Spacer(minLength: 0)
                profileValue(value).multilineTextAlignment(.trailing)
            }
        }
    }

    private func profileValue(_ value: String) -> some View {
        Text(value.isEmpty ? "Not set" : value).foregroundColor(value.isEmpty ? .secondary : .primary)
            .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
    }

    private var appVersion: String {
        "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"
    }

    private func refreshProfile(completion: (() -> Void)? = nil) {
        guard !refreshing && !se.isAccountActionPending else { completion?(); return }
        refreshing = true
        se.refreshProfile { success, message in
            refreshing = false
            error = success ? nil : message
            completion?()
        }
    }

    private func performSignOut() {
        guard !busy else { return }
        error = nil
        checkingConnection = true
        AF.request(cameraURL + "stat") { $0.timeoutInterval = 1 }.response { response in
            checkingConnection = false
            if case .success = response.result {
                error = "Disconnect from \(deviceName) before signing out."
            } else {
                se.logout { success, message in if !success { error = message } }
            }
        }
    }
}

struct ProfileEditView: View {
    @ObservedObject var se: Session
    @Environment(\.dismiss) private var dismiss
    @State private var profileName = ""
    @State private var profileEmail = ""
    @State private var originalName = ""
    @State private var originalEmail = ""
    @State private var initialized = false
    @State private var saving = false
    @State private var discard = false
    @State private var error: String?

    private var changed: Bool { profileName != originalName || profileEmail != originalEmail }
    private var valid: Bool { AccountValidation.nameIsValid(profileName) && AccountValidation.emailIsValid(profileEmail, optional: true) }

    var body: some View {
        OilixNavigation {
            Form {
                Section(header: Text("Profile")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name:").font(.subheadline)
                        TextField("Name", text: $profileName).textContentType(.name)
                            .accessibilityIdentifier("profile.name")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email:").font(.subheadline)
                        TextField("Email", text: $profileEmail).textContentType(.emailAddress).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).disableAutocorrection(true)
                            .accessibilityIdentifier("profile.email")
                    }
                    if !AccountValidation.emailIsValid(profileEmail, optional: true) {
                        FormMessage(text: "Enter a valid email address.")
                    }
                    if !AccountValidation.nameIsValid(profileName) { FormMessage(text: "Use up to 50 characters for your name.") }
                }
                if let error = error { Section { FormMessage(text: error) } }
                if saving { Section { ProgressView("Saving Profile...") } }
            }
            .disabled(saving)
            .oilixKeyboardDismissal()
            .navigationTitle("Edit Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                        .accessibilityIdentifier("profile.keyboardDone")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { if changed { discard = true } else { dismiss() } }
                        .disabled(saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!changed || !valid || saving)
                        .accessibilityIdentifier("profile.save")
                }
            }
        }
        .interactiveDismissDisabled(changed || saving)
        .onAppear {
            guard !initialized else { return }
            profileName = se.displayName; originalName = se.displayName
            profileEmail = se.email; originalEmail = se.email; initialized = true
        }
        .alert("Discard profile changes?", isPresented: $discard) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) { }
        }
    }

    private func save() {
        guard valid && changed && !saving else { return }
        saving = true
        error = nil
        se.updateProfile(displayName: profileName.trimmingCharacters(in: .whitespacesAndNewlines),
                         email: profileEmail.trimmingCharacters(in: .whitespacesAndNewlines)) { success, message in
            saving = false
            if success { dismiss() } else { error = message }
        }
    }
}
