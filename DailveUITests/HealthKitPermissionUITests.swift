import XCTest

/// UI test that launches the app and auto-accepts HealthKit permission dialogs.
/// Run this test once on a fresh simulator before running unit tests to ensure
/// HealthKit authorization is granted. Without this, HealthKit queries in unit tests
/// may fail with authorization errors.
///
/// Usage:
///   xcodebuild test -project Dailve/Dailve.xcodeproj -scheme DailveUITests \
///     -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.2' \
///     -only-testing DailveUITests/HealthKitPermissionUITests
@MainActor
final class HealthKitPermissionUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        // Do NOT pass --uitesting so the app triggers real HealthKit authorization
        app.launch()
    }

    /// Automatically handles HealthKit and other system permission dialogs.
    /// The interruption monitor intercepts system alerts (HealthKit auth sheet,
    /// notification permission, etc.) and taps the appropriate accept button.
    func testGrantHealthKitPermission() throws {
        // Register interruption monitor for system alerts
        addUIInterruptionMonitor(withDescription: "System Permission Alert") { alert in
            // HealthKit authorization sheet has "Allow" button
            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }

            // Some permission dialogs use "OK"
            let okButton = alert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
                return true
            }

            // Notification permission
            let dontAllowButton = alert.buttons["Don't Allow"]
            if dontAllowButton.exists {
                dontAllowButton.tap()
                return true
            }

            return false
        }

        // Navigate to Activity tab to trigger HealthKit queries
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            // Tap Activity/Train tab
            let trainTab = tabBar.buttons["Train"]
            if trainTab.exists {
                trainTab.tap()
            } else {
                let activityTab = tabBar.buttons["Activity"]
                if activityTab.exists {
                    activityTab.tap()
                }
            }
        }

        // Wait for HealthKit authorization sheet to appear and be handled
        sleep(3)

        // Tap on the app to trigger the interruption handler
        app.tap()
        sleep(1)

        // HealthKit auth sheet: if the full authorization view appears,
        // look for "Turn On All" toggle and "Allow" button
        let healthKitSheet = app.navigationBars["Health Access"]
        if healthKitSheet.waitForExistence(timeout: 5) {
            // Tap "Turn On All" if available
            let turnOnAll = app.switches["Turn On All"]
            if turnOnAll.exists {
                turnOnAll.tap()
            }

            // Tap "Allow" to confirm
            let allow = app.buttons["Allow"]
            if allow.waitForExistence(timeout: 3) {
                allow.tap()
            }
        }

        // Navigate to Today tab to trigger HRV/RHR queries
        if tabBar.exists {
            let todayTab = tabBar.buttons["Today"]
            if todayTab.exists {
                todayTab.tap()
            }
        }

        sleep(3)
        app.tap()
        sleep(1)

        // Handle any additional permission dialogs
        if healthKitSheet.waitForExistence(timeout: 5) {
            let turnOnAll = app.switches["Turn On All"]
            if turnOnAll.exists {
                turnOnAll.tap()
            }
            let allow = app.buttons["Allow"]
            if allow.waitForExistence(timeout: 3) {
                allow.tap()
            }
        }

        // Verify app is still running
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
