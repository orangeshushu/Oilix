import XCTest
import UIKit
import Alamofire
@testable import Oilix

final class SamplingTests: XCTestCase {
    @MainActor
    private func samples(_ count: Int) -> WaterSampleViewModel {
        let model = WaterSampleViewModel()
        let image = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 24)).image { context in
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 24))
        }
        for _ in 0..<count { model.add(image: image, location: "0,0", times: Date()) }
        return model
    }

    func testCoordinatesRejectInvalidValues() {
        XCTAssertNil(History.getLocation(locStr: "invalid"))
        XCTAssertNil(History.getLocation(locStr: "91,0"))
        XCTAssertNil(History.getLocation(locStr: "0,181"))
        XCTAssertNil(History.getLocation(locStr: "nan,0"))
        let coordinate = History.getLocation(locStr: " 38.952 , -92.329 ")
        XCTAssertEqual(coordinate?.latitude, 38.952)
        XCTAssertEqual(coordinate?.longitude, -92.329)
    }

    @MainActor
    func testRemovingLastImageReturnsEmptySelection() {
        let model = samples(2)
        let lastID = model.samples[1].id
        XCTAssertTrue(model.delete(0))
        XCTAssertEqual(model.samples[0].id, lastID)
        XCTAssertTrue(model.delete(0))
        XCTAssertEqual(model.count, 0)
        XCTAssertFalse(model.delete(0))
    }

    func testUploadFailureCanDecodeWithoutPrediction() throws {
        let response = try JSONDecoder().decode(UploadResponse.self, from: Data(
            #"{"status":6,"msg":"GPS error.","meta":{"attempted_username":"user"}}"#.utf8))
        XCTAssertEqual(response.msg, "GPS error.")
        XCTAssertNil(response.meta?.result)
    }

    @MainActor
    func testSuccessfulBatchRecordsPredictions() async {
        let fixture = UploadFixture(responses: [
            #"{"status":0,"msg":"Uploaded","meta":{"result":"12.09"}}"#,
            #"{"status":0,"msg":"Uploaded","meta":{"result":"97.37"}}"#
        ])
        let controller = SampleUploadController(network: fixture.network)
        let model = samples(2)
        let done = expectation(description: "batch finished")
        controller.start(samples: model) { successes, errors in
            XCTAssertEqual(successes, 2)
            XCTAssertTrue(errors.isEmpty)
            done.fulfill()
        }
        await fulfillment(of: [done], timeout: 10)
        XCTAssertFalse(controller.isBusy)
        XCTAssertEqual(controller.completedCount, 2)
        XCTAssertEqual(model.samples.map(\.result), ["12.09", "97.37"])
        XCTAssertTrue(model.samples.allSatisfy(\.online))
        XCTAssertEqual(fixture.uploadCount, 2)
        controller.start(samples: model) { _, _ in XCTFail("Uploaded samples must not be sent again") }
        XCTAssertFalse(controller.isBusy)
        XCTAssertEqual(fixture.uploadCount, 2)
    }

    @MainActor
    func testPartialFailureRetainsOnlyFailedImageForRetry() async {
        let fixture = UploadFixture(responses: [
            #"{"status":6,"msg":"GPS error.","meta":{}}"#,
            #"{"status":0,"msg":"Uploaded","meta":{"result":"20"}}"#,
            #"{"status":0,"msg":"Uploaded","meta":{"result":"30"}}"#
        ])
        let controller = SampleUploadController(network: fixture.network)
        let model = samples(2)
        let first = expectation(description: "partial batch")
        controller.start(samples: model) { successes, errors in
            XCTAssertEqual(successes, 1)
            XCTAssertEqual(errors, ["Image 1: GPS error."])
            first.fulfill()
        }
        await fulfillment(of: [first], timeout: 10)
        XCTAssertFalse(model.samples[0].online)
        XCTAssertTrue(model.samples[1].online)
        let retry = expectation(description: "retry pending image")
        controller.start(samples: model) { successes, errors in
            XCTAssertEqual(successes, 1)
            XCTAssertTrue(errors.isEmpty)
            retry.fulfill()
        }
        await fulfillment(of: [retry], timeout: 10)
        XCTAssertEqual(fixture.uploadCount, 3)
        XCTAssertEqual(model.samples.map(\.result), ["30", "20"])
    }

    @MainActor
    func testBatchUsesStableIDsAndIgnoresNewSelections() async {
        let fixture = UploadFixture(responses: [
            #"{"status":0,"msg":"Uploaded","meta":{"result":"11"}}"#,
            #"{"status":0,"msg":"Uploaded","meta":{"result":"22"}}"#
        ])
        let controller = SampleUploadController(network: fixture.network)
        let model = samples(2)
        let secondID = model.samples[1].id
        let done = expectation(description: "stable batch")
        controller.start(samples: model) { successes, _ in
            XCTAssertEqual(successes, 2)
            done.fulfill()
        }
        model.delete(0)
        let image = UIImage(systemName: "photo")!
        model.add(image: image, location: "0,0", times: Date())
        await fulfillment(of: [done], timeout: 10)
        XCTAssertEqual(model.samples[0].id, secondID)
        XCTAssertEqual(model.samples[0].result, "22")
        XCTAssertTrue(model.samples[0].online)
        XCTAssertFalse(model.samples[1].online)
        XCTAssertEqual(fixture.uploadCount, 2)
    }

    @MainActor
    func testRepeatedTapStartsOnlyOneBatch() async {
        let fixture = UploadFixture(responses: [
            #"{"status":0,"msg":"Uploaded","meta":{"result":"10"}}"#
        ])
        let controller = SampleUploadController(network: fixture.network)
        let model = samples(1)
        let done = expectation(description: "single batch")
        controller.start(samples: model) { _, _ in done.fulfill() }
        controller.start(samples: model) { _, _ in XCTFail("A second batch must not start while busy") }
        await fulfillment(of: [done], timeout: 10)
        XCTAssertEqual(fixture.uploadCount, 1)
    }

    @MainActor
    func testCameraConnectionLeavesSelectionUntouched() async {
        let fixture = UploadFixture(responses: [], cameraConnected: true)
        let controller = SampleUploadController(network: fixture.network)
        let model = samples(1)
        let done = expectation(description: "camera connection")
        controller.start(samples: model) { successes, errors in
            XCTAssertEqual(successes, 0)
            XCTAssertTrue(errors[0].contains("Disconnect"))
            done.fulfill()
        }
        await fulfillment(of: [done], timeout: 10)
        XCTAssertFalse(controller.isBusy)
        XCTAssertFalse(model.samples[0].online)
        XCTAssertEqual(fixture.uploadCount, 0)
    }

    @MainActor
    func testUnconfirmedUploadExplainsHistoryCheck() async {
        let fixture = UploadFixture(responses: ["invalid response"])
        let controller = SampleUploadController(network: fixture.network)
        let model = samples(1)
        let done = expectation(description: "unconfirmed upload")
        controller.start(samples: model) { successes, errors in
            XCTAssertEqual(successes, 0)
            XCTAssertTrue(errors[0].contains("Check History before retrying"))
            done.fulfill()
        }
        await fulfillment(of: [done], timeout: 10)
        XCTAssertFalse(controller.isBusy)
        XCTAssertFalse(model.samples[0].online)
    }

    @MainActor
    func testCancellingDoesNotStartUploadsAfterConnectionCheck() async {
        let fixture = UploadFixture(responses: [])
        let controller = SampleUploadController(network: fixture.network)
        let model = samples(1)
        controller.start(samples: model) { _, _ in XCTFail("Cancelled batch must not complete") }
        controller.cancel()
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(controller.isBusy)
        XCTAssertFalse(model.samples[0].online)
        XCTAssertEqual(fixture.uploadCount, 0)
    }
}

private final class UploadFixture {
    let network: Alamofire.Session
    private let lock = NSLock()
    private var count = 0
    var uploadCount: Int { lock.lock(); defer { lock.unlock() }; return count }

    init(responses: [String], cameraConnected: Bool = false) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UploadProtocol.self]
        network = Alamofire.Session(configuration: configuration)
        UploadProtocol.handle = { [weak self] request in
            if request.url?.path == "/stat" {
                return cameraConnected ? Data("connected".utf8) : nil
            }
            guard let self = self else { return nil }
            self.lock.lock()
            let index = self.count
            self.count += 1
            self.lock.unlock()
            return Data((index < responses.count ? responses[index] : "unexpected upload").utf8)
        }
    }
}

private final class UploadProtocol: URLProtocol {
    static var handle: ((URLRequest) -> Data?)?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let data = Self.handle?(request) else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}
