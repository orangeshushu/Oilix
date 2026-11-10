import Foundation
import NetworkExtension
import SwiftUI

enum ESP32Connection {
    static func probeURL(for address: String) -> URL? {
        let input = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let absolute = input.contains("://") ? input : "http://" + input
        guard let parts = URLComponents(string: absolute),
              parts.scheme == "http", let host = parts.host,
              parts.user == nil, parts.password == nil, parts.query == nil, parts.fragment == nil,
              parts.path.isEmpty || parts.path == "/",
              parts.port.map({ (1...65535).contains($0) }) ?? true else { return nil }

        let fields = host.split(separator: ".", omittingEmptySubsequences: false)
        let octets = fields.compactMap { UInt8($0) }
        guard fields.count == 4, octets.count == 4,
              octets.map(String.init).joined(separator: ".") == host else { return nil }
        guard octets[0] == 10 ||
              (octets[0] == 172 && (16...31).contains(octets[1])) ||
              (octets[0] == 192 && octets[1] == 168) else { return nil }

        var endpoint = URLComponents()
        endpoint.scheme = "http"
        endpoint.host = host
        endpoint.port = parts.port
        endpoint.path = "/"
        return endpoint.url
    }

    static func joinWiFi(ssid: String, password: String) async throws {
        let configuration = password.isEmpty
            ? NEHotspotConfiguration(ssid: ssid)
            : NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        configuration.joinOnce = true
        do {
            try await NEHotspotConfigurationManager.shared.apply(configuration)
        } catch let error as NSError where error.domain == NEHotspotConfigurationErrorDomain &&
            error.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
            return
        }
    }

    static func probe(_ url: URL, configuration: URLSessionConfiguration = .ephemeral) async throws -> Int {
        configuration.allowsCellularAccess = false
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 12
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        let session = URLSession(configuration: configuration, delegate: NoRedirects(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        // Read headers from the root GET without downloading the response body or triggering a capture.
        let (_, response) = try await session.bytes(from: url)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return http.statusCode
    }

    private final class NoRedirects: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                        completionHandler: @escaping (URLRequest?) -> Void) {
            completionHandler(nil)
        }
    }
}

struct ESP32ConnectionView: View {
    private enum Status: Equatable {
        case idle, joining, testing, response(Int), failure(String)
    }

    @Environment(\.dismiss) private var dismiss
    @State private var ssid = "Oilix"
    @State private var password = ""
    @State private var address = "192.168.1.87"
    @State private var status: Status = .idle
    @State private var operation: Task<Void, Never>?

    private var busy: Bool { operation != nil }

    private var canJoinWiFi: Bool {
        #if targetEnvironment(simulator) || OILIX_MANUAL_WIFI
        false
        #else
        true
        #endif
    }

    var body: some View {
        OilixNavigation {
            Form {
                Section("Device Wi-Fi") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Network Name").font(.caption).foregroundColor(.secondary)
                        TextField("Network Name", text: $ssid)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password").font(.caption).foregroundColor(.secondary)
                        SecureField("Password", text: $password)
                    }
                }
                .disabled(busy)

                Section("Device Address") {
                    TextField("Local IP address", text: $address)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .disabled(busy)
                }

                Section {
                    if canJoinWiFi {
                        Button { start(join: true) } label: {
                            Label("Join Wi-Fi and Test", systemImage: "wifi")
                                .frame(minHeight: 44)
                        }
                        .disabled(busy || ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Button { start(join: false) } label: {
                        Label("Test on Current Wi-Fi", systemImage: "network")
                            .frame(minHeight: 44)
                    }
                    .disabled(busy)
                }

                Section("Connection Status") {
                    switch status {
                    case .idle:
                        Label("Not tested", systemImage: "circle.dashed")
                            .foregroundColor(.secondary)
                    case .joining:
                        ProgressView("Joining Wi-Fi...")
                    case .testing:
                        ProgressView("Checking device address...")
                    case .response(let code):
                        let ok = (200..<300).contains(code)
                        Label("HTTP response: \(code)", systemImage: ok ? "checkmark.circle" : "exclamationmark.circle")
                            .foregroundColor(ok ? .green : .orange)
                    case .failure(let message):
                        FormMessage(text: message)
                    }
                }
            }
            .navigationTitle("ESP32 Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.disabled(status == .joining)
                }
            }
        }
        .interactiveDismissDisabled(status == .joining)
        .onDisappear { operation?.cancel() }
        .onChange(of: address) { _ in if !busy { status = .idle } }
        .onChange(of: ssid) { _ in if !busy { status = .idle } }
    }

    private func start(join: Bool) {
        guard !busy else { return }
        guard let url = ESP32Connection.probeURL(for: address) else {
            status = .failure("Enter a private IPv4 address, with an optional port.")
            return
        }
        let network = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
        let passphrase = password
        status = join ? .joining : .testing
        operation = Task { @MainActor in
            defer { operation = nil }
            if join {
                do {
                    try await ESP32Connection.joinWiFi(ssid: network, password: passphrase)
                } catch {
                    guard !Task.isCancelled else { return }
                    let failure = error as NSError
                    let declined = failure.domain == NEHotspotConfigurationErrorDomain &&
                        failure.code == NEHotspotConfigurationError.userDenied.rawValue
                    status = .failure(declined ? "Wi-Fi connection cancelled." :
                        "Could not join Wi-Fi. Check the password or connect in Settings, then test again.")
                    return
                }
            }
            do {
                try Task.checkCancellation()
                status = .testing
                let code = try await ESP32Connection.probe(url)
                try Task.checkCancellation()
                status = .response(code)
                password = ""
            } catch {
                guard !Task.isCancelled else { return }
                status = .failure("No HTTP response. Check the device address, Wi-Fi, and Local Network permission.")
            }
        }
    }
}
