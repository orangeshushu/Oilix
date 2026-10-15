import XCTest
import UIKit

final class InstructionsUITests: XCTestCase {
    func testAppStoreScreenshots() throws {
        guard ProcessInfo.processInfo.environment["OILIX_STORE_SCREENSHOTS"] == "1" else {
            throw XCTSkip("Store screenshot capture is opt-in.")
        }
        let login = XCUIApplication()
        login.launch()
        XCTAssertTrue(login.buttons["login.signIn"].waitForExistence(timeout: 10))
        XCTAssertTrue(login.segmentedControls.buttons["User"].isSelected)
        attach("Store-05-Login")
        login.terminate()

        let app = try signedInApp()
        XCTAssertTrue(app.buttons["sampling.chooseImages"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.tabBars.buttons.count, 4)
        attach("Store-01-Sampling")
        app.tabBars.buttons["Instructions"].tap()
        XCTAssertTrue(app.buttons["instructions.preparation"].waitForExistence(timeout: 5))
        attach("Store-02-Instructions")
        tap(app.buttons["instructions.preparation"], in: app)
        XCTAssertTrue(app.staticTexts["instructions.currentStep"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["instructions.stepCount"].label, "Step 1 of 8")
        attach("Store-04-Sample-Guide")
        app.navigationBars["Prepare a sample"].buttons.element(boundBy: 0).tap()
        tap(app.buttons["instructions.replayTour"], in: app)
        XCTAssertTrue(app.buttons["tour.next"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["tour.title"].label, "Start with a sample image")
        attach("Store-03-First-Use-Tour")
        app.buttons["tour.skip"].tap()
    }

    func testAuthorizedTourAndGroupedSettings() throws {
        let environment = ProcessInfo.processInfo.environment
        if environment["OILIX_REDUCE_MOTION_QA"] == "1" {
            XCTAssertTrue(UIAccessibility.isReduceMotionEnabled)
        }
        let app = try signedInApp()
        try verifyTourAndSettings(app, environment: environment)
    }

    private func signedInApp() throws -> XCUIApplication {
        let environment = ProcessInfo.processInfo.environment
        guard environment["OILIX_LIVE_QA"] == "1",
              let username = environment["OILIX_TEST_USERNAME"],
              let password = environment["OILIX_TEST_PASSWORD"] else {
            throw XCTSkip("This read-only check requires owner-supplied live credentials.")
        }
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.segmentedControls.buttons["Admin"].waitForExistence(timeout: 10))
        app.segmentedControls.buttons["Admin"].tap()
        tap(app.textFields["login.username"], in: app)
        app.textFields["login.username"].typeText(username)
        app.keyboards.buttons["next"].tap()
        app.secureTextFields["login.password"].typeText(password)
        app.buttons["login.keyboardDone"].tap()
        app.buttons["login.signIn"].tap()
        XCTAssertTrue(app.tabBars.buttons["Sampling"].waitForExistence(timeout: 30))
        if app.buttons["tour.skip"].waitForExistence(timeout: 3) { app.buttons["tour.skip"].tap() }
        return app
    }

    private func verifyTourAndSettings(_ app: XCUIApplication, environment: [String: String]) throws {
        XCTAssertEqual(app.tabBars.buttons.count, 4)
        XCTAssertEqual(app.tabBars.buttons.element(boundBy: 0).label, "Sampling")
        XCTAssertTrue(app.buttons["sampling.chooseImages"].waitForExistence(timeout: 5))
        attach("Centered sampling start")
        let camera = app.buttons["sampling.cameraShortcut"]
        XCTAssertGreaterThanOrEqual(camera.frame.width, 112)
        XCTAssertGreaterThanOrEqual(camera.frame.height, 112)
        XCTAssertEqual(camera.frame.midX, app.windows.firstMatch.frame.midX, accuracy: 1)
        tap(camera, in: app)
        XCTAssertTrue(app.buttons["camera.done"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["camera.capture"].exists)
        app.buttons["camera.done"].tap()
        XCTAssertTrue(app.buttons["sampling.chooseImages"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Instructions"].tap()
        attach("Action-first instructions")
        XCTAssertFalse(app.staticTexts["instructions.introduction"].exists)
        tap(app.buttons["instructions.replayTour"], in: app)
        XCTAssertTrue(app.buttons["tour.next"].waitForExistence(timeout: 5))
        attach("First use image selection spotlight")
        app.buttons["tour.next"].tap()
        XCTAssertEqual(app.staticTexts["tour.title"].label, "Capture a new sample")
        app.buttons["tour.back"].tap()
        XCTAssertEqual(app.staticTexts["tour.title"].label, "Start with a sample image")
        app.buttons["tour.next"].tap()
        app.buttons["tour.next"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["tour.title"].label, "Find your uploaded samples")
        app.buttons["tour.next"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        attach("Profile group spotlight")
        app.buttons["tour.next"].tap()
        XCTAssertEqual(app.staticTexts["tour.title"].label, "Help is always here")
        app.buttons["tour.next"].tap()
        XCTAssertTrue(app.buttons["sampling.chooseImages"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tour.next"].exists)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertFalse(app.buttons["settings.editProfile"].exists)
        attach("Grouped settings")
        tap(app.buttons["Personal Profile"], in: app)
        tap(app.buttons["settings.editProfile"], in: app)
        XCTAssertTrue(app.navigationBars["Edit Profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["profile.name"].exists)
        XCTAssertFalse(app.buttons["profile.save"].isEnabled)
        app.navigationBars["Edit Profile"].buttons["Cancel"].tap()
        // Return to the top before collapsing a long accessibility-size profile.
        for _ in 0..<6 where !app.buttons["Personal Profile"].isHittable { scrollable(in: app).swipeDown() }
        tap(app.buttons["Personal Profile"], in: app)
        tap(app.buttons["settings.acknowledgements"], in: app)
        XCTAssertTrue(app.navigationBars["Acknowledgements"].waitForExistence(timeout: 5))
        for _ in 0..<6 where !app.staticTexts["University of Missouri"].exists { scrollable(in: app).swipeUp() }
        XCTAssertTrue(app.staticTexts["University of Missouri"].exists)
        attach("Project acknowledgements")
        app.navigationBars["Acknowledgements"].buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Instructions"].tap()
        tap(app.buttons["instructions.replayTour"], in: app)
        app.buttons["tour.skip"].tap()
        XCTAssertTrue(app.buttons["sampling.chooseImages"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tour.next"].exists)
        app.tabBars.buttons["Instructions"].tap()
        tap(app.buttons["instructions.replayTour"], in: app)
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tour.next"].exists)
        if environment["OILIX_LANDSCAPE_QA"] == "1" {
            XCUIDevice.shared.orientation = .landscapeLeft
            app.tabBars.buttons["Instructions"].tap()
            // Rotation preserves the list offset; the replay row may now be above the viewport.
            for _ in 0..<6 where !app.buttons["instructions.replayTour"].isHittable { scrollable(in: app).swipeDown() }
            tap(app.buttons["instructions.replayTour"], in: app)
            XCTAssertTrue(app.buttons["tour.next"].isHittable)
            XCTAssertTrue(app.buttons["tour.skip"].isHittable)
            attach("Landscape accessible tour")
            app.buttons["tour.skip"].tap()
        }
    }

    func testSharedDatabaseHistoryAndImages() throws {
        let app = try signedInApp()
        app.tabBars.buttons["History"].tap()
        let scope = app.buttons["history.scope"]
        XCTAssertTrue(scope.waitForExistence(timeout: 5))
        XCTAssertTrue(scope.label.contains("All Samples"))
        let allReady = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: scope)
        XCTAssertEqual(XCTWaiter.wait(for: [allReady], timeout: 30), .completed)
        let allCount = app.staticTexts["history.count"].label
        attach("All database samples with thumbnails")
        let firstRecord = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history.record.")).firstMatch
        XCTAssertTrue(firstRecord.waitForExistence(timeout: 10))
        firstRecord.tap()
        XCTAssertTrue(app.navigationBars["Sample Details"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["detail.image"].waitForExistence(timeout: 30))
        attach("Database sample image loaded")
        if ProcessInfo.processInfo.environment["OILIX_DETAIL_LAYOUT_QA"] == "1" {
            let preview = app.buttons["detail.image"]
            XCTAssertGreaterThanOrEqual(preview.frame.minY, app.navigationBars["Sample Details"].frame.maxY)
            preview.tap()
            XCTAssertTrue(app.navigationBars["Sample Image"].waitForExistence(timeout: 5))
            let zoom = app.scrollViews["detail.zoom"]
            XCTAssertTrue(zoom.waitForExistence(timeout: 5))
            zoom.doubleTap()
            let zoomed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "300%"), object: zoom)
            XCTAssertEqual(XCTWaiter.wait(for: [zoomed], timeout: 5), .completed)
            attach("Full screen sample zoom")
            app.navigationBars["Sample Image"].buttons["Done"].tap()
            let details = app.scrollViews["detail.content"]
            details.swipeUp()
            attach("Sample result and metadata")
            details.swipeUp()
            details.swipeUp()
            XCTAssertTrue(app.staticTexts["detail.noLocation"].isHittable || app.buttons["Open in Maps"].isHittable)
            attach("Sample notes and location")
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(app.navigationBars["Sample Details"].buttons["Done"].isHittable)
            attach("Landscape sample details")
            XCUIDevice.shared.orientation = .portrait
        }
        app.navigationBars["Sample Details"].buttons["Done"].tap()
        scope.tap()
        app.buttons["My Samples"].tap()
        XCTAssertTrue(scope.label.contains("My Samples"))
        let mineReady = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: scope)
        XCTAssertEqual(XCTWaiter.wait(for: [mineReady], timeout: 30), .completed)
        let mineCount = app.staticTexts["history.count"].label
        XCTAssertGreaterThanOrEqual(Int(allCount.split(separator: " ").first ?? "") ?? -1,
                                    Int(mineCount.split(separator: " ").first ?? "") ?? 0)
        attach("Personal samples with thumbnails")
        scope.tap()
        app.buttons["All Samples"].tap()
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: scope)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 30), .completed)
        XCTAssertEqual(app.staticTexts["history.count"].label, allCount)
        if ProcessInfo.processInfo.environment["OILIX_HISTORY_LAYOUT_QA"] == "1" {
            let list = app.collectionViews.firstMatch
            list.swipeUp(velocity: .fast)
            attach("History while scrolling")
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(firstRecord.waitForExistence(timeout: 5) || app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history.record.")).count > 0)
            attach("Landscape history")
            XCUIDevice.shared.orientation = .portrait
        }
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        XCUIApplication().terminate()
        XCUIDevice.shared.orientation = .portrait
    }

    func testSignInLayoutKeepsAccountActionsVisible() {
        let app = XCUIApplication()
        app.launch()
        let button = app.buttons["login.signIn"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(button.frame.height, 50)
        XCTAssertLessThanOrEqual(button.frame.height, 72)
        XCTAssertTrue(app.buttons["Create Account"].isHittable)
        XCTAssertTrue(app.buttons["Forgot Password?"].isHittable)
        let logos = app.descendants(matching: .any)["login.logos"]
        XCTAssertTrue(logos.exists)
        // Accessibility geometry may contain subpixel rounding at the scroll view edge.
        XCTAssertEqual(logos.frame.midX, app.windows.firstMatch.frame.midX, accuracy: 1.01)
        XCTAssertGreaterThanOrEqual(logos.frame.height, 80)
        let username = app.textFields["login.username"]
        let password = app.secureTextFields["login.password"]
        XCTAssertEqual(username.frame.minX, password.frame.minX, accuracy: 1)
        XCTAssertEqual(username.frame.width, password.frame.width, accuracy: 1)
        XCTAssertEqual(username.frame.height, password.frame.height, accuracy: 1)
        XCTAssertEqual(app.staticTexts["Username"].frame.midY, username.frame.midY, accuracy: 1)
        XCTAssertEqual(app.staticTexts["Password"].frame.midY, password.frame.midY, accuracy: 1)
        attach("Compact sign in")
    }

    func testPasswordVisibilityKeepsDraftAndFieldAligned() {
        let app = XCUIApplication()
        app.launch()
        let password = app.secureTextFields["login.password"]
        XCTAssertTrue(password.waitForExistence(timeout: 10))
        password.tap(); password.typeText("layout-test")
        app.buttons["login.password.visibility"].tap()
        let revealed = app.textFields["login.password"]
        XCTAssertEqual(revealed.value as? String, "layout-test")
        XCTAssertEqual(app.textFields["login.username"].frame.minX, revealed.frame.minX, accuracy: 1)
        XCTAssertEqual(app.textFields["login.username"].frame.width, revealed.frame.width, accuracy: 1)
        app.buttons["login.password.visibility"].tap()
        XCTAssertTrue(password.exists)
        XCTAssertFalse(app.buttons["login.signIn"].isEnabled)
    }

    func testClearingUsernameKeepsPasswordDraft() {
        let app = XCUIApplication()
        app.launch()
        let username = app.textFields["login.username"]
        username.tap(); username.typeText("field-user")
        app.secureTextFields["login.password"].tap()
        app.secureTextFields["login.password"].typeText("layout-test")
        app.buttons["login.keyboardDone"].tap()
        app.buttons["login.username.clear"].tap()
        XCTAssertEqual(username.value as? String, "Required")
        app.buttons["login.password.visibility"].tap()
        XCTAssertEqual(app.textFields["login.password"].value as? String, "layout-test")
        XCTAssertFalse(app.buttons["login.signIn"].isEnabled)
    }

    func testGuideIsAvailableBeforeSignInAndPreservesForm() {
        let app = XCUIApplication()
        app.launch()
        let username = app.textFields["login.username"]
        XCTAssertTrue(username.waitForExistence(timeout: 10))
        username.tap()
        username.typeText("field-user")
        app.buttons["login.instructions"].tap()
        XCTAssertTrue(app.navigationBars["Instructions"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["instructions.preparation"].isHittable)
        XCTAssertTrue(app.buttons["instructions.analysis"].isHittable)
        XCTAssertTrue(app.buttons["instructions.database"].isHittable)
        XCTAssertFalse(app.staticTexts["instructions.introduction"].exists)
        attach("Compact instructions overview")
        XCTAssertFalse(app.buttons["instructions.openSampling"].exists)
        tap(app.buttons["instructions.analysis"], in: app)
        XCTAssertTrue(app.navigationBars["Analyze an image"].waitForExistence(timeout: 5))
        attach("Image analysis instructions")
        app.navigationBars["Analyze an image"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["instructions.done"].waitForExistence(timeout: 5))
        app.buttons["instructions.done"].tap()
        XCTAssertEqual(username.value as? String, "field-user")
    }

    func testStepByStepReadingAndFullProcedure() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["login.instructions"].tap()
        tap(app.buttons["instructions.preparation"], in: app)
        XCTAssertTrue(app.staticTexts["instructions.stepCount"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["instructions.stepCount"].label, "Step 1 of 8")
        XCTAssertFalse(app.buttons["instructions.previousStep"].isEnabled)
        tap(app.buttons["instructions.nextStep"], in: app)
        XCTAssertEqual(app.staticTexts["instructions.stepCount"].label, "Step 2 of 8")
        XCTAssertTrue(app.staticTexts["instructions.currentStep"].label.contains("10 ml of hexane"))
        attach("Preparation one step at a time")
        if ProcessInfo.processInfo.environment["OILIX_LANDSCAPE_QA"] == "1" {
            XCUIDevice.shared.orientation = .landscapeLeft
            tap(app.buttons["instructions.nextStep"], in: app)
            XCTAssertEqual(app.staticTexts["instructions.stepCount"].label, "Step 3 of 8")
            attach("Landscape step reading")
            tap(app.buttons["instructions.previousStep"], in: app)
            XCUIDevice.shared.orientation = .portrait
        }
        tap(app.buttons["instructions.previousStep"], in: app)
        XCTAssertEqual(app.staticTexts["instructions.stepCount"].label, "Step 1 of 8")
        for _ in 0..<7 { tap(app.buttons["instructions.nextStep"], in: app) }
        XCTAssertEqual(app.staticTexts["instructions.stepCount"].label, "Step 8 of 8")
        XCTAssertFalse(app.buttons["instructions.nextStep"].isEnabled)
        app.segmentedControls.buttons["All Steps"].tap()
        XCTAssertFalse(app.staticTexts["instructions.stepCount"].exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Collect a 10 ml")).firstMatch.exists)
        app.segmentedControls.buttons["Step by Step"].tap()
        XCTAssertEqual(app.staticTexts["instructions.stepCount"].label, "Step 8 of 8")
        app.navigationBars["Prepare a sample"].buttons.element(boundBy: 0).tap()
        tap(app.buttons["About Oilix"], in: app)
        XCTAssertTrue(app.staticTexts["instructions.introduction"].exists)
    }

    func testPreparationAndDatabaseInstructions() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["login.instructions"].tap()
        tap(app.buttons["instructions.preparation"], in: app)
        XCTAssertTrue(app.navigationBars["Prepare a sample"].waitForExistence(timeout: 5))
        attach("Sample preparation")
        app.segmentedControls.buttons["All Steps"].tap()
        scrollable(in: app).swipeUp()
        attach("Sample preparation continued")
        app.navigationBars["Prepare a sample"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["instructions.database"].waitForExistence(timeout: 5))
        for _ in 0..<4 where !app.buttons["instructions.database"].isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons["instructions.database"].isHittable)
        app.buttons["instructions.database"].tap()
        XCTAssertTrue(app.navigationBars["Use the database"].waitForExistence(timeout: 5))
        attach("Database instructions")
    }

    func testAccountModesAndDisabledSignIn() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["login.brandTitle"].exists)
        XCTAssertTrue(app.staticTexts["login.brandSubtitle"].exists)
        let accountType = app.segmentedControls["login.accountType"]
        XCTAssertGreaterThanOrEqual(accountType.frame.height, 44)
        XCTAssertTrue(accountType.buttons["User"].isSelected)
        XCTAssertFalse(app.buttons["login.signIn"].isEnabled)
        app.segmentedControls.buttons["Admin"].tap()
        XCTAssertTrue(accountType.buttons["Admin"].isSelected)
        XCTAssertFalse(accountType.buttons["User"].isSelected)
        attach("Selected administrator sign in")
        XCTAssertTrue(app.buttons["Admin Sign In"].exists)
        XCTAssertFalse(app.buttons["Create Account"].exists)
        app.segmentedControls.buttons["User"].tap()
        XCTAssertTrue(accountType.buttons["User"].isSelected)
        XCTAssertTrue(app.buttons["Create Account"].exists)
        attach("Login")
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testRegistrationValidationAndDraftProtection() {
        let app = XCUIApplication()
        app.launch()
        tap(app.buttons["Create Account"], in: app)
        XCTAssertTrue(app.textFields["register.username"].waitForExistence(timeout: 5))
        app.textFields["register.username"].tap()
        app.textFields["register.username"].typeText("field-user")
        app.secureTextFields["register.password"].tap()
        app.secureTextFields["register.password"].typeText("sample-pass1")
        tap(app.buttons["register.password.visibility"], in: app)
        XCTAssertEqual(app.textFields["register.password"].value as? String, "sample-pass1")
        app.secureTextFields["register.confirmation"].tap()
        app.secureTextFields["register.confirmation"].typeText("different-pass")
        app.buttons["register.keyboardDone"].tap()
        for _ in 0..<6 where !app.buttons["register.submit"].exists { app.swipeUp() }
        XCTAssertFalse(app.buttons["register.submit"].isEnabled)
        attach("Account validation")
        app.navigationBars.buttons["Cancel"].tap()
        app.buttons["Keep Editing"].tap()
        XCTAssertEqual(app.textFields["register.username"].value as? String, "field-user")
        app.navigationBars.buttons["Cancel"].tap()
        app.buttons["Discard"].tap()
        XCTAssertTrue(app.buttons["login.instructions"].exists)
    }

    func testPasswordResetPrefillsUsernameAndProtectsDraft() {
        let app = XCUIApplication()
        app.launch()
        let username = app.textFields["login.username"]
        username.tap(); username.typeText("field-user")
        app.buttons["login.keyboardDone"].tap()
        tap(app.buttons["Forgot Password?"], in: app)
        XCTAssertTrue(app.textFields["reset.username"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["reset.username"].value as? String, "field-user")
        app.textFields["reset.email"].tap()
        app.textFields["reset.email"].typeText("invalid")
        app.buttons["reset.keyboardDone"].tap()
        for _ in 0..<6 where !app.buttons["reset.submit"].exists { app.swipeUp() }
        XCTAssertFalse(app.buttons["reset.submit"].isEnabled)
        attach("Password reset")
        app.navigationBars.buttons["Cancel"].tap()
        app.buttons["Keep Editing"].tap()
        XCTAssertEqual(app.textFields["reset.email"].value as? String, "invalid")
    }

    private func tap(_ button: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 where !button.isHittable { scrollable(in: app).swipeUp() }
        XCTAssertTrue(button.isHittable)
        button.tap()
    }

    private func scrollable(in app: XCUIApplication) -> XCUIElement {
        if app.collectionViews.firstMatch.exists { return app.collectionViews.firstMatch }
        if app.scrollViews.firstMatch.exists { return app.scrollViews.firstMatch }
        return app
    }

    func testLandscapeLoginKeepsFieldsAndInstructionsAccessible() {
        let app = XCUIApplication()
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let username = app.textFields["login.username"]
        tap(username, in: app)
        username.typeText("field-user")
        app.buttons["login.keyboardDone"].tap()
        XCTAssertGreaterThan(app.windows.firstMatch.frame.width, app.windows.firstMatch.frame.height)
        app.buttons["login.instructions"].tap()
        XCTAssertTrue(app.navigationBars["Instructions"].waitForExistence(timeout: 5))
        tap(app.buttons["instructions.analysis"], in: app)
        XCTAssertTrue(app.navigationBars["Analyze an image"].waitForExistence(timeout: 5))
        attach("Landscape instructions")
        app.buttons["Done"].tap()
        XCTAssertEqual(username.value as? String, "field-user")
        attach("Landscape login")
    }
}
