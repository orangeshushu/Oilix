//
//  CameraView.swift
//  Oilix
//
//  Created by Guo, Congyu on 6/3/22.
//

import SwiftUI
import Combine
import Alamofire
import AudioToolbox
import CoreLocation

@MainActor
final class OilixCameraController: ObservableObject {
    @Published private(set) var connected = false
    @Published private(set) var checking = false
    @Published private(set) var capturing = false
    @Published private(set) var image: UIImage?
    @Published private(set) var errorMessage: String?
    private let network: Alamofire.Session
    private let baseURL: String
    private var statusRequest: DataRequest?
    private var captureRequest: DataRequest?
    private var generation = 0
    private var active = false

    init(network: Alamofire.Session = .default, baseURL: String = cameraURL) {
        self.network = network
        self.baseURL = baseURL
    }

    func start() {
        active = true
        checkConnection()
    }

    func checkConnection() {
        guard active, !checking, !capturing else { return }
        checking = true
        let token = generation
        statusRequest = network.request(baseURL + "stat") { $0.timeoutInterval = 2 }
            .validate(statusCode: 200..<300)
            .response { response in
                guard self.active, token == self.generation else { return }
                self.checking = false
                self.statusRequest = nil
                self.connected = response.error == nil
            }
    }

    func capture(completion: @escaping (UIImage) -> Void) {
        guard active, connected, !capturing else { return }
        statusRequest?.cancel()
        statusRequest = nil
        checking = false
        // A generation also prevents a cancelled status reply from overriding a newer capture.
        generation += 1
        let token = generation
        capturing = true
        errorMessage = nil
        captureRequest = network.request(baseURL + "capture") { $0.timeoutInterval = 15 }
            .validate(statusCode: 200..<300)
            .responseData { response in
                guard self.active, token == self.generation else { return }
                self.capturing = false
                self.captureRequest = nil
                guard case .success(let data) = response.result, let image = UIImage(data: data) else {
                    self.errorMessage = "The image could not be captured. Check the camera connection and try again."
                    self.connected = false
                    return
                }
                self.image = image
                completion(image)
            }
    }

    func stop() {
        active = false
        generation += 1
        statusRequest?.cancel()
        captureRequest?.cancel()
        statusRequest = nil
        captureRequest = nil
        checking = false
        capturing = false
        connected = false
    }
}

struct CameraView: View {
    @ObservedObject var samples: WaterSampleViewModel
    @Binding var picker: Bool
    @Binding var isPresented: Bool
    @StateObject private var camera = OilixCameraController()
    @StateObject private var locationManager = LocationManager(startImmediately: false)
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var heightClass
    @Environment(\.dynamicTypeSize) private var typeSize
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    private var currentLocation: CLLocation? {
        guard locationManager.hasAccess, let location = locationManager.lastLocation,
              LocationManager.isUsable(location) else { return nil }
        return location
    }

    var body: some View {
        OilixNavigation {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label(camera.connected ? "Camera connected" : camera.checking ? "Connecting..." : "Camera not connected",
                          systemImage: camera.connected ? "video" : "video.slash")
                        .font(.headline).accessibilityIdentifier("camera.connection")
                    if let image = camera.image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: heightClass == .compact ? 160 : 280)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityLabel("Latest captured sample")
                    } else {
                        Image(systemName: "camera").font(.system(size: 48)).foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: heightClass == .compact ? 100 : 180)
                            .accessibilityHidden(true)
                    }
                    if !camera.connected {
                        Text("Connect to the \(accessPointName) Wi-Fi network and allow Local Network access for Oilix in Settings.")
                            .foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                        HStack {
                            Button("Retry") { camera.checkConnection() }.disabled(camera.checking || camera.capturing)
                            Spacer()
                            Button("Open Settings", action: openSettings)
                        }.frame(minHeight: 44)
                    }
                    if let error = camera.errorMessage { FormMessage(text: error) }
                    Label(currentLocation != nil
                          ? "Current location available" : locationManager.statusString,
                          systemImage: currentLocation != nil ? "location" : "location.slash")
                        .font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                    if locationManager.locationStatus == .denied {
                        Button("Location Settings", action: openSettings).frame(minHeight: 44)
                    }
                    if typeSize.isAccessibilitySize { captureControls }
                }
                .padding(20).frame(maxWidth: 640, alignment: .leading).frame(maxWidth: .infinity)
            }
            .navigationTitle(deviceName).navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !typeSize.isAccessibilitySize {
                    VStack(spacing: 0) {
                        Divider()
                        captureControls.padding(.horizontal, 20).padding(.vertical, 8)
                    }.background(.regularMaterial)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                        .accessibilityIdentifier("camera.done")
                }
            }
        }
        .onAppear { camera.start(); locationManager.start() }
        .onDisappear { camera.stop(); locationManager.stop() }
        .onReceive(timer) { _ in if scenePhase == .active { camera.checkConnection() } }
        .onChange(of: scenePhase) { phase in
            if phase == .active { camera.start(); locationManager.start() }
            else { camera.stop(); locationManager.stop() }
        }
    }

    private var captureControls: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                if let image = camera.image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: 56, height: 56).clipped().cornerRadius(8).accessibilityHidden(true)
                }
                Text("\(samples.count) selected").font(.subheadline).foregroundColor(.secondary)
            }
            Spacer(minLength: 8)
            Button {
                camera.capture { image in
                    let location = currentLocation
                    let gps = location.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" } ?? "0,0"
                    samples.add(image: image, location: gps, times: Date())
                    AudioServicesPlaySystemSound(1108)
                }
            } label: {
                ZStack {
                    Circle().strokeBorder(Color.primary, lineWidth: 3)
                    if camera.capturing { ProgressView() }
                    else { Image(systemName: "camera.fill").font(.system(size: 24, weight: .semibold)) }
                }.frame(width: 68, height: 68)
            }
            .buttonStyle(.plain).disabled(!camera.connected || camera.capturing)
            .accessibilityLabel(camera.capturing ? "Capturing image" : "Capture image")
            .accessibilityIdentifier("camera.capture")
        }.padding(.vertical, 8)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}
