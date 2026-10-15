import XCTest
import UIKit
import CoreLocation
import Combine
import Alamofire
@testable import Oilix

final class CompatibilityTests: XCTestCase {
    func testLocationRejectsStaleInvalidAndFutureReadings() {
        let now = Date()
        func point(age: TimeInterval, accuracy: Double = 10, latitude: Double = 38.95) -> CLLocation {
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: -92.33),
                       altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: 10,
                       timestamp: now.addingTimeInterval(-age))
        }
        XCTAssertTrue(LocationManager.isUsable(point(age: 10), now: now))
        XCTAssertFalse(LocationManager.isUsable(point(age: 121), now: now))
        XCTAssertFalse(LocationManager.isUsable(point(age: -121), now: now))
        XCTAssertFalse(LocationManager.isUsable(point(age: 0, accuracy: -1), now: now))
        XCTAssertFalse(LocationManager.isUsable(point(age: 0, latitude: 100), now: now))
    }

    @MainActor func testLocationWaitsForPermissionAndStartsAfterGrant() {
        let manager = LocationFixture()
        let model = LocationManager(startImmediately: false, manager: manager)
        XCTAssertEqual(manager.permissionRequests, 0)
        model.start()
        XCTAssertEqual(manager.permissionRequests, 1)
        XCTAssertEqual(manager.updates, 0)
        manager.status = .authorizedWhenInUse
        model.locationManagerDidChangeAuthorization(manager)
        XCTAssertGreaterThan(manager.updates, 0)
        XCTAssertTrue(model.hasAccess)
        model.stop()
        let updates = manager.updates
        model.locationManagerDidChangeAuthorization(manager)
        XCTAssertEqual(manager.updates, updates)
    }

    @MainActor func testDeniedLocationDoesNotRepeatedlyPromptAndClearsOldGPS() {
        let manager = LocationFixture()
        manager.status = .denied
        let model = LocationManager(startImmediately: false, manager: manager)
        model.lastLocation = CLLocation(latitude: 38.95, longitude: -92.33)
        model.start()
        XCTAssertEqual(manager.permissionRequests, 0)
        XCTAssertEqual(manager.updates, 0)
        XCTAssertFalse(model.hasAccess)
        XCTAssertNil(model.lastLocation)
        XCTAssertTrue(model.statusString.contains("Settings"))
    }

    @MainActor func testCameraCaptureCompletesOnceAndIgnoresDoubleTap() async {
        let fixture = CameraFixture(status: 200, body: Self.jpeg())
        let model = OilixCameraController(network: fixture.network, baseURL: "https://camera.example/")
        await connect(model)
        XCTAssertTrue(model.connected)
        let done = expectation(description: "capture")
        model.capture { image in XCTAssertGreaterThan(image.size.width, 0); done.fulfill() }
        model.capture { _ in XCTFail("Duplicate capture") }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertEqual(fixture.paths, ["/stat", "/capture"])
        XCTAssertNotNil(model.image)
        XCTAssertFalse(model.capturing)
        model.stop()
    }

    @MainActor func testCameraInvalidImageRecoversAndRetainsPreview() async {
        let fixture = CameraFixture(status: 200, body: Self.jpeg())
        let model = OilixCameraController(network: fixture.network, baseURL: "https://camera.example/")
        await connect(model)
        let first = expectation(description: "first capture")
        model.capture { _ in first.fulfill() }
        await fulfillment(of: [first], timeout: 5)
        fixture.body = Data("not an image".utf8)
        let failed = expectation(description: "capture failure")
        let observer = model.$errorMessage.compactMap { $0 }.sink { _ in failed.fulfill() }
        model.capture { _ in XCTFail("Invalid image must not become a sample") }
        await fulfillment(of: [failed], timeout: 5)
        withExtendedLifetime(observer) {}
        XCTAssertNotNil(model.image)
        XCTAssertFalse(model.connected)
        XCTAssertFalse(model.capturing)
        model.stop()
    }

    @MainActor func testCameraHTTPErrorCannotReportConnected() async {
        let fixture = CameraFixture(status: 500, body: Data())
        let model = OilixCameraController(network: fixture.network, baseURL: "https://camera.example/")
        let done = expectation(description: "status error")
        let observer = model.$checking.dropFirst().filter { !$0 }.prefix(1).sink { _ in done.fulfill() }
        model.start()
        await fulfillment(of: [done], timeout: 5)
        withExtendedLifetime(observer) {}
        XCTAssertFalse(model.connected)
        model.capture { _ in XCTFail("Offline camera must not capture") }
        XCTAssertEqual(fixture.paths, ["/stat"])
        model.stop()
    }

    @MainActor func testCameraClosingIgnoresLateImageAndStopsPolling() async {
        let fixture = CameraFixture(status: 200, body: Self.jpeg())
        let model = OilixCameraController(network: fixture.network, baseURL: "https://camera.example/")
        await connect(model)
        fixture.delay = 0.2
        model.capture { _ in XCTFail("A closed camera must not add a late sample") }
        model.stop()
        model.checkConnection()
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertFalse(model.capturing)
        XCTAssertFalse(model.checking)
        XCTAssertFalse(model.connected)
        XCTAssertNil(model.image)
    }

    @MainActor private func connect(_ model: OilixCameraController) async {
        let done = expectation(description: "camera connected")
        let observer = model.$connected.dropFirst().sink { if $0 { done.fulfill() } }
        model.start()
        await fulfillment(of: [done], timeout: 5)
        withExtendedLifetime(observer) {}
    }

    private static func jpeg() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.green.setFill(); context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }.jpegData(compressionQuality: 1)!
    }
}

private final class LocationFixture: CLLocationManager {
    var status: CLAuthorizationStatus = .notDetermined
    var permissionRequests = 0
    var updates = 0
    override var authorizationStatus: CLAuthorizationStatus { status }
    override func requestWhenInUseAuthorization() { permissionRequests += 1 }
    override func startUpdatingLocation() { updates += 1 }
    override func stopUpdatingLocation() {}
}

private final class CameraFixture {
    var status: Int
    var body: Data
    var delay: TimeInterval = 0
    var paths = [String]()
    let network: Alamofire.Session
    init(status: Int, body: Data) {
        self.status = status; self.body = body
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [CameraProtocol.self]
        network = Alamofire.Session(configuration: config)
        CameraProtocol.handle = { [weak self] request in
            guard let self = self else { return (500, Data(), 0) }
            self.paths.append(request.url!.path)
            return (self.status, self.body, self.delay)
        }
    }
    deinit { CameraProtocol.handle = nil }
}

private final class CameraProtocol: URLProtocol {
    static var handle: ((URLRequest) -> (Int, Data, TimeInterval))?
    private var stopped = false
    private let lock = NSLock()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let (status, data, delay) = Self.handle?(request) ?? (500, Data(), 0)
        let work = DispatchWorkItem {
            self.lock.lock()
            defer { self.lock.unlock() }
            guard !self.stopped else { return }
            let response = HTTPURLResponse(url: self.request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
    }
    override func stopLoading() { lock.lock(); stopped = true; lock.unlock() }
}
