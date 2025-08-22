@testable import Accounts
import MEGAL10n
import XCTest

final class CancelSubscriptionStepsHelperTests: XCTestCase {

    // MARK: - Google subscription
    func testLoadCancellationData_googleSubscription_returnsCorrectTitle() {
        let data = makeSUTAndLoadData(type: .google)

        XCTAssertEqual(data.title, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.title)
    }

    func testLoadCancellationData_googleSubscription_returnsCorrectMessage() {
        let data = makeSUTAndLoadData(type: .google)

        XCTAssertEqual(data.message, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.message)
    }

    func testLoadCancellationData_googleSubscription_returnsCorrectSectionsCount() {
        let data = makeSUTAndLoadData(type: .google)

        XCTAssertEqual(data.sections.count, 2)
    }

    func testLoadCancellationData_googleSubscription_returnsCorrectWebBrowserSection() {
        let data = makeSUTAndLoadData(type: .google)
        let webBrowserSection = data.sections[0]

        XCTAssertEqual(webBrowserSection.title, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.title)
        XCTAssertEqual(webBrowserSection.steps.count, 6)
        verifyGoogleWebBrowserSteps(steps: webBrowserSection.steps)
    }

    func testLoadCancellationData_googleSubscription_returnsCorrectAndroidDeviceSection() {
        let data = makeSUTAndLoadData(type: .google)
        let androidDeviceSection = data.sections[1]
        
        XCTAssertEqual(androidDeviceSection.title, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.title)
        XCTAssertEqual(androidDeviceSection.steps.count, 6)
        verifyGoogleAndroidDeviceSteps(steps: androidDeviceSection.steps)
    }
    
    // MARK: - Webclient subscription
    func testLoadCancellationData_webclientSubscription_returnsCorrectTitle() {
        let data = makeSUTAndLoadData(type: .webClient)

        XCTAssertEqual(data.title, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.title)
    }
    
    func testLoadCancellationData_webclientSubscription_returnsCorrectMessage() {
        let data = makeSUTAndLoadData(type: .webClient)

        XCTAssertEqual(data.message, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.message)
    }
    
    func testLoadCancellationData_webclientSubscription_returnsCorrectSectionsCount() {
        let data = makeSUTAndLoadData(type: .webClient)

        XCTAssertEqual(data.sections.count, 2)
    }
    
    func testLoadCancellationData_webclientSubscription_returnsCorrectComputerSection() {
        ["mega.nz", "mega.app"].forEach { appDomain in
            let data = makeSUTAndLoadData(type: .webClient, appDomain: appDomain)
            let computerSection = data.sections[0]

            XCTAssertEqual(computerSection.title, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.title)
            XCTAssertEqual(computerSection.steps.count, 6)

            verifyWebclientOnComputerSteps(steps: computerSection.steps, appDomain: appDomain)
        }
    }
    
    func testLoadCancellationData_webclientSubscription_returnsCorrectMobileDeviceSection() {
        ["mega.nz", "mega.app"].forEach { appDomain in
            let data = makeSUTAndLoadData(type: .webClient, appDomain: appDomain)
            let mobileSection = data.sections[1]

            XCTAssertEqual(mobileSection.title, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.title)
            XCTAssertEqual(mobileSection.steps.count, 4)

            verifyWebclientOnMobileSteps(steps: mobileSection.steps, appDomain: appDomain)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUTAndLoadData(type: SubscriptionType, appDomain: String? = nil) -> CancelSubscriptionData {
        let sut = CancelSubscriptionStepsHelper(type: type)
        if let appDomain {
            Accounts.DependencyInjection.appDomain = appDomain
        }
        return sut.loadCancellationData()
    }

    private func verifyGoogleWebBrowserSteps(
        steps: [Step],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(steps[0].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.one, file: file, line: line)
        XCTAssertEqual(steps[1].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.two, file: file, line: line)
        XCTAssertEqual(steps[2].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.three, file: file, line: line)
        XCTAssertEqual(steps[3].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.four, file: file, line: line)
        XCTAssertEqual(steps[4].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.five, file: file, line: line)
        XCTAssertEqual(steps[5].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.six, file: file, line: line)
    }

    private func verifyGoogleAndroidDeviceSteps(
        steps: [Step],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(steps[0].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.one, file: file, line: line)
        XCTAssertEqual(steps[1].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.two, file: file, line: line)
        XCTAssertEqual(steps[2].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.three, file: file, line: line)
        XCTAssertEqual(steps[3].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.four, file: file, line: line)
        XCTAssertEqual(steps[4].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.five, file: file, line: line)
        XCTAssertEqual(steps[5].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.six, file: file, line: line)
    }
    
    private func verifyWebclientOnComputerSteps(
        steps: [Step],
        appDomain: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            steps[0].text,
            Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.one(appDomain),
            file: file,
            line: line
        )
        XCTAssertEqual(steps[1].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.two, file: file, line: line)
        XCTAssertEqual(steps[2].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.three, file: file, line: line)
        XCTAssertEqual(steps[3].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.four, file: file, line: line)
        XCTAssertEqual(steps[4].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.five, file: file, line: line)
        XCTAssertEqual(steps[5].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.six, file: file, line: line)
    }
    
    private func verifyWebclientOnMobileSteps(
        steps: [Step],
        appDomain: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            steps[0].text,
            Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.Step.one(appDomain),
            file: file,
            line: line
        )
        XCTAssertEqual(steps[1].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.Step.two, file: file, line: line)
        XCTAssertEqual(steps[2].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.Step.three, file: file, line: line)
        XCTAssertEqual(steps[3].text, Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.Step.four, file: file, line: line)
    }
}
