import XCTest
import UIKit
import ImageIO
import UniformTypeIdentifiers
import Combine
import Alamofire
@testable import Oilix

final class UsabilityTests: XCTestCase {
    func testFirstUseGuideCompletesOnceAndCanBeReplayed() {
        let suite = "OilixTourTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let tour = OilixTour(defaults: defaults)
        tour.startIfNeeded()
        XCTAssertEqual(tour.step, .images)
        for step in OilixTourStep.allCases {
            XCTAssertEqual(tour.step, step)
            tour.next()
        }
        XCTAssertNil(tour.step)
        let nextLaunch = OilixTour(defaults: defaults)
        nextLaunch.startIfNeeded()
        XCTAssertNil(nextLaunch.step)
        nextLaunch.replay()
        XCTAssertEqual(nextLaunch.step, .images)
    }

    func testSkippingGuideDoesNotChangeOtherPreferences() {
        let suite = "OilixTourTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("Saved User", forKey: "username")
        defaults.set(false, forKey: "deleteConfirm")
        let tour = OilixTour(defaults: defaults)
        tour.startIfNeeded()
        tour.finish()
        XCTAssertNil(tour.step)
        XCTAssertTrue(defaults.bool(forKey: OilixTour.completionKey))
        XCTAssertEqual(defaults.string(forKey: "username"), "Saved User")
        XCTAssertFalse(defaults.bool(forKey: "deleteConfirm"))
        let nextLaunch = OilixTour(defaults: defaults)
        nextLaunch.startIfNeeded()
        XCTAssertNil(nextLaunch.step)
    }

    func testGuideBackAndRepeatedStartPreserveProgress() {
        let suite = "OilixTourTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let tour = OilixTour(defaults: defaults)
        tour.back()
        XCTAssertNil(tour.step)
        tour.startIfNeeded()
        tour.back()
        XCTAssertEqual(tour.step, .images)
        tour.next()
        tour.startIfNeeded()
        XCTAssertEqual(tour.step, .camera)
        tour.back()
        XCTAssertEqual(tour.step, .images)
        tour.finish()
        tour.next()
        XCTAssertNil(tour.step)
    }

    func testGuideUsesExistingTabIdentities() {
        XCTAssertEqual(OilixTourStep.allCases.map(\.tab), [2, 2, 1, 3, 4])
        XCTAssertEqual(OilixTourStep.allCases.count, 5)
    }

    func testInstructionsPreserveAllReferenceSections() {
        XCTAssertEqual(OilixGuideTopic.allCases, [.preparation, .analysis, .database])
        XCTAssertEqual(OilixGuideTopic.preparation.steps.count, 8)
        XCTAssertEqual(OilixGuideTopic.analysis.steps.count, 5)
        XCTAssertEqual(OilixGuideTopic.database.steps.count, 4)
        XCTAssertTrue(OilixGuideTopic.preparation.steps[1].contains("10 ml of hexane"))
        XCTAssertTrue(OilixGuideTopic.analysis.steps[2].contains("remove incorrect images"))
        XCTAssertTrue(OilixGuideTopic.database.steps[0].contains("wateroil.web.app"))
    }

    func testAccountValidation() {
        XCTAssertFalse(AccountValidation.usernameIsValid("   "))
        XCTAssertTrue(AccountValidation.usernameIsValid("field-user"))
        XCTAssertFalse(AccountValidation.usernameIsValid(String(repeating: "a", count: 256)))
        XCTAssertFalse(AccountValidation.newPasswordIsValid("short"))
        XCTAssertFalse(AccountValidation.newPasswordIsValid("        "))
        XCTAssertTrue(AccountValidation.newPasswordIsValid("sample-pass1"))
        XCTAssertTrue(AccountValidation.emailIsValid("", optional: true))
        XCTAssertFalse(AccountValidation.emailIsValid(""))
        XCTAssertFalse(AccountValidation.emailIsValid("not-an-email"))
        XCTAssertTrue(AccountValidation.emailIsValid(" field+test@example.com "))
        XCTAssertTrue(AccountValidation.nameIsValid(String(repeating: "a", count: 50)))
        XCTAssertFalse(AccountValidation.nameIsValid(String(repeating: "a", count: 51)))
    }

    @MainActor
    func testFailedSignOutPreservesAccount() async {
        let fixture = NetworkFixture([#"{"status":9,"msg":"Try again"}"#])
        let session = Session(network: fixture.network)
        session.isLoggedIn = true; session.name = "Field User"; session.displayName = "Jeff"
        let done = expectation(description: "sign out failure")
        session.logout { success, _ in XCTAssertFalse(success); done.fulfill() }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertTrue(session.isLoggedIn)
        XCTAssertEqual(session.name, "Field User")
        XCTAssertEqual(session.displayName, "Jeff")
        XCTAssertFalse(session.isAccountActionPending)
    }

    @MainActor
    func testMalformedDeletionDoesNotPretendToSucceed() async {
        let fixture = NetworkFixture(["invalid response"])
        let session = Session(network: fixture.network)
        session.isLoggedIn = true; session.name = "Field User"
        let done = expectation(description: "deletion failure")
        session.deleteUser { success, message in
            XCTAssertFalse(success); XCTAssertTrue(message.contains("could not be confirmed")); done.fulfill()
        }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertTrue(session.isLoggedIn)
        XCTAssertEqual(session.name, "Field User")
    }

    @MainActor
    func testConfirmedSignOutClearsAccountOnce() async {
        let fixture = NetworkFixture([#"{"status":0,"msg":"Signed out"}"#])
        let session = Session(network: fixture.network)
        session.isLoggedIn = true; session.isAdmin = true; session.name = "Field User"
        let done = expectation(description: "confirmed sign out")
        session.logout { success, _ in XCTAssertTrue(success); done.fulfill() }
        session.logout { _, _ in XCTFail("A second account request must not be started") }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertFalse(session.isLoggedIn)
        XCTAssertFalse(session.isAdmin)
        XCTAssertTrue(session.name.isEmpty)
        XCTAssertEqual(fixture.requestCount, 1)
    }

    @MainActor
    func testLegacyPasswordCanSignInWithoutPlaintextPersistence() async {
        let fixture = NetworkFixture([#"{"status":0,"msg":"OK","meta":{"name":"Jeff","email":"field@example.com"}}"#])
        let suite = "OilixTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("legacy", forKey: "password")
        let session = Session(network: fixture.network, defaults: defaults)
        session.name = "Field User"; session.psw = "old"
        let done = expectation(description: "login")
        let observer = session.$isLoggedIn.dropFirst().sink { if $0 { done.fulfill() } }
        session.login(asAdmin: true)
        await fulfillment(of: [done], timeout: 5)
        withExtendedLifetime(observer) { }
        XCTAssertTrue(session.isAdmin)
        XCTAssertEqual(session.displayName, "Jeff")
        XCTAssertNil(defaults.object(forKey: "password"))
        XCTAssertEqual(session.psw, "")
    }

    @MainActor
    func testInvalidLoginResponseStopsSpinner() async {
        let fixture = NetworkFixture(["invalid response"])
        let session = Session(network: fixture.network)
        let done = expectation(description: "login failure")
        let observer = session.$showAlert.dropFirst().sink { if $0 { done.fulfill() } }
        session.login()
        await fulfillment(of: [done], timeout: 5)
        withExtendedLifetime(observer) { }
        XCTAssertFalse(session.loading)
        XCTAssertFalse(session.isLoggedIn)
    }

    @MainActor
    func testProfileRejectionKeepsSavedValues() async {
        let fixture = NetworkFixture([#"{"status":8,"msg":"Login timeout"}"#])
        let session = Session(network: fixture.network)
        session.displayName = "Jeff"; session.email = "field@example.com"
        let done = expectation(description: "profile rejection")
        session.updateProfile(displayName: "New", email: "new@example.com") { success, message in
            XCTAssertFalse(success); XCTAssertEqual(message, "Login timeout"); done.fulfill()
        }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertEqual(session.displayName, "Jeff")
        XCTAssertEqual(session.email, "field@example.com")
    }

    @MainActor
    func testFailedProfileRefreshKeepsPreviousProfile() async {
        let fixture = NetworkFixture(["invalid response"])
        let session = Session(network: fixture.network)
        session.displayName = "Jeff"
        let done = expectation(description: "profile refresh")
        session.refreshProfile { success, _ in XCTAssertFalse(success); done.fulfill() }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertEqual(session.displayName, "Jeff")
    }

    @MainActor
    func testHistoryCollectsPagesAndSortsSameDayNewestFirst() async {
        let fixture = NetworkFixture([
            historyPage(page: 1, total: 2, records: [record(id: 1, date: "2026-10-08"), record(id: 2, date: "2026-10-09")]),
            historyPage(page: 2, total: 2, records: [record(id: 3, date: "2026-10-09")])
        ])
        let history = History(network: fixture.network)
        let done = expectation(description: "history pagination")
        history.getHistory { done.fulfill() }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertEqual(history.data.map(\.serverID), [3, 2, 1])
        XCTAssertEqual(history.data.map(\.id), ["3", "2", "1"])
        XCTAssertFalse(history.isLoading)
        XCTAssertNil(history.errorMessage)
        XCTAssertEqual(fixture.requestCount, 2)
    }

    @MainActor
    func testFailedLaterPagePreservesPreviousSnapshot() async {
        let fixture = NetworkFixture([
            historyPage(page: 1, total: 1, records: [record(id: 5, date: "2026-10-09")]),
            historyPage(page: 1, total: 2, records: [record(id: 1, date: "2026-10-08")]),
            #"{"status":9,"msg":"Try again"}"#
        ])
        let history = History(network: fixture.network)
        let first = expectation(description: "initial snapshot")
        history.getHistory { first.fulfill() }
        await fulfillment(of: [first], timeout: 5)
        let second = expectation(description: "failed refresh")
        history.getHistory { second.fulfill() }
        await fulfillment(of: [second], timeout: 5)
        XCTAssertEqual(history.data.map(\.serverID), [5])
        XCTAssertEqual(history.errorMessage, "Try again")
        XCTAssertFalse(history.isLoading)
    }

    @MainActor
    func testRepeatedPageResponseDoesNotLoop() async {
        let fixture = NetworkFixture([
            historyPage(page: 1, total: 2, records: [record(id: 1, date: "2026-10-09")]),
            historyPage(page: 1, total: 2, records: [record(id: 1, date: "2026-10-09")])
        ])
        let history = History(network: fixture.network)
        let done = expectation(description: "invalid pagination")
        history.getHistory { done.fulfill() }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertTrue(history.data.isEmpty)
        XCTAssertNotNil(history.errorMessage)
        XCTAssertEqual(fixture.requestCount, 2)
    }

    @MainActor
    func testCancelledImportIgnoresLateProgressAndCancelsProvider() {
        let samples = WaterSampleViewModel()
        let token = samples.beginImport(total: 2)
        let progress = Progress(totalUnitCount: 2)
        samples.trackImport(progress, generation: token)
        samples.cancelImport()
        samples.updateImport(completed: 1, total: 2, generation: token)
        XCTAssertFalse(samples.isImporting)
        XCTAssertTrue(progress.isCancelled)
        XCTAssertNotEqual(samples.importGeneration, token)
    }

    @MainActor
    func testUploadCannotStartDuringImport() {
        let samples = WaterSampleViewModel()
        samples.add(image: UIImage(systemName: "photo")!, location: "0,0", times: Date())
        _ = samples.beginImport(total: 2)
        let controller = SampleUploadController()
        controller.start(samples: samples) { _, _ in XCTFail("Import must complete before uploading") }
        XCTAssertFalse(controller.isBusy)
    }

    func testImageReaderRejectsUnreadableData() {
        XCTAssertNil(SampleImageReader.read(Data("not an image".utf8)))
    }

    func testImageReaderPreservesGPSAndCaptureDate() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.green.setFill(); context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 38.952, kCGImagePropertyGPSLatitudeRef: "N",
                                            kCGImagePropertyGPSLongitude: 92.329, kCGImagePropertyGPSLongitudeRef: "W"],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:10:09 15:30:00"]
        ]
        CGImageDestinationAddImage(destination, try XCTUnwrap(image.cgImage), properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let sample = try XCTUnwrap(SampleImageReader.read(data as Data, fallbackDate: .distantPast))
        let coordinate = try XCTUnwrap(History.getLocation(locStr: sample.location))
        XCTAssertEqual(coordinate.latitude, 38.952, accuracy: 0.000001)
        XCTAssertEqual(coordinate.longitude, -92.329, accuracy: 0.000001)
        XCTAssertEqual(Calendar.current.component(.year, from: sample.date), 2026)
    }

    @MainActor
    func testAdminHistoryDefaultsToAllAndLoadsEveryPage() async {
        let fixture = NetworkFixture([
            historyPage(page: 1, total: 2, records: [record(id: 1, date: "2026-10-08")]),
            historyPage(page: 2, total: 2, records: [record(id: 2, date: "2026-10-09")])
        ])
        let history = History(network: fixture.network, isAdmin: true)
        XCTAssertEqual(history.scope, .all)
        let done = expectation(description: "all users and pages")
        history.getHistory { done.fulfill() }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertEqual(fixture.paths, ["/adminphotolist", "/adminphotolist"])
        XCTAssertEqual(history.data.map(\.serverID), [2, 1])
        XCTAssertEqual(history.data.first?.username, "field-user")
    }

    @MainActor
    func testScopeChangeClearsAllSamplesBeforePersonalHistoryFailure() async {
        let fixture = NetworkFixture([
            historyPage(page: 1, total: 1, records: [record(id: 1, date: "2026-10-08")]),
            #"{"status":8,"msg":"Login timeout"}"#,
            historyPage(page: 1, total: 1, records: [record(id: 2, date: "2026-10-09")])
        ])
        let history = History(network: fixture.network, isAdmin: true)
        let first = expectation(description: "all loaded")
        history.getHistory { first.fulfill() }
        await fulfillment(of: [first], timeout: 5)
        let second = expectation(description: "my history failure")
        history.selectScope(.mine) { second.fulfill() }
        XCTAssertTrue(history.data.isEmpty)
        await fulfillment(of: [second], timeout: 5)
        XCTAssertEqual(history.scope, .mine)
        XCTAssertTrue(history.data.isEmpty)
        XCTAssertEqual(history.errorMessage, "Login timeout")
        let third = expectation(description: "all restored")
        history.selectScope(.all) { third.fulfill() }
        await fulfillment(of: [third], timeout: 5)
        XCTAssertEqual(history.data.map(\.serverID), [2])
        XCTAssertEqual(fixture.paths, ["/adminphotolist", "/history", "/adminphotolist"])
    }

    @MainActor
    func testRegularUserCannotSelectAllSamples() async {
        let fixture = NetworkFixture([historyPage(page: 1, total: 1, records: [])])
        let history = History(network: fixture.network)
        history.selectScope(.all)
        XCTAssertEqual(history.scope, .mine)
        XCTAssertFalse(history.canViewAllSamples)
        XCTAssertEqual(fixture.requestCount, 0)
        let done = expectation(description: "personal history")
        history.getHistory { done.fulfill() }
        await fulfillment(of: [done], timeout: 5)
        XCTAssertEqual(fixture.paths, ["/history"])
    }

    private func record(id: Int, date: String) -> String {
        "\"\(id)\":{\"id\":\(id),\"path\":\"static/images/\(id).jpeg\",\"gps\":\"0,0\",\"date\":\"\(date)\",\"result\":\"12\",\"notes\":\"Sample\",\"tags\":\"\",\"username\":\"field-user\"}"
    }

    private func historyPage(page: Int, total: Int, records: [String]) -> String {
        "{\"status\":0,\"msg\":{\(records.joined(separator: ","))},\"meta\":{\"total_page\":\(total),\"current_page\":\(page),\"attempted_username\":\"Field User\"}}"
    }
}

private final class NetworkFixture {
    let network: Alamofire.Session
    private let lock = NSLock()
    private var count = 0
    private var requestedPaths = [String]()
    var paths: [String] { lock.lock(); defer { lock.unlock() }; return requestedPaths }
    var requestCount: Int { lock.lock(); defer { lock.unlock() }; return count }
    init(_ responses: [String]) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        network = Alamofire.Session(configuration: configuration)
        FixtureProtocol.handle = { [weak self] request in
            guard let self = self else { return nil }
            self.lock.lock()
            let index = self.count
            self.count += 1
            self.requestedPaths.append(request.url?.path ?? "")
            self.lock.unlock()
            return index < responses.count ? Data(responses[index].utf8) : nil
        }
    }
}

private final class FixtureProtocol: URLProtocol {
    static var handle: ((URLRequest) -> Data?)?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let data = Self.handle?(request) else { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)); return }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { }
}
