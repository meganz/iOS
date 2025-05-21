@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAssets
import Testing

struct PermissionOnboardingViewModelTests {

    @Test("On appear should track correct event")
    func onAppear() async {
        let tracker = MockTracker()
        let permissionHandler = MockOnboardingPermissionHandler(requestPermissionValue: false)
        let sut = makeSut(permissionHandler: permissionHandler, tracker: tracker)

        await sut.onAppear()
        #expect(tracker.trackedEventIdentifiers.first?.uniqueIdentifier == 0)
    }

    @Test("On primary button tap should change route to .finished with correct result",
    arguments: [true, false])
    func primaryButtonTap(permissionGranted: Bool) async {
        let tracker = MockTracker()
        let permissionHandler = MockOnboardingPermissionHandler(
            requestPermissionValue: permissionGranted
        )
        let sut = makeSut(permissionHandler: permissionHandler, tracker: tracker)

        await sut.onPrimaryButtonTap()
        #expect(sut.route == .finished(result: permissionGranted))
        var trackedEventIdentifiers = tracker.trackedEventIdentifiers
        #expect(trackedEventIdentifiers.removeFirst().uniqueIdentifier == 1)
        if permissionGranted {
            #expect(trackedEventIdentifiers.removeFirst().uniqueIdentifier == 3)
        }
    }

    @Test("On secondary button tap should change route to .skipped")
    func secondaryButtonTap() async {
        let tracker = MockTracker()
        let permissionHandler = MockOnboardingPermissionHandler(requestPermissionValue: false)
        let sut = makeSut(permissionHandler: permissionHandler, tracker: tracker)

        await sut.onSecondaryButtonTap()
        #expect(sut.route == .skipped)
        #expect(tracker.trackedEventIdentifiers.first?.uniqueIdentifier == 2)
    }

    private func makeSut(
        permissionHandler: MockOnboardingPermissionHandler,
        tracker: MockTracker
    ) -> PermissionOnboardingViewModel {
        PermissionOnboardingViewModel(
            image: MEGAAssets.Image.info,
            title: "title",
            description: "description",
            note: nil,
            primaryButtonTitle: "primaryButtonTitle",
            secondaryButtonTitle: "secondaryButtonTitle",
            permissionHandler: permissionHandler,
            tracker: tracker
        )
    }
}

private final class MockOnboardingPermissionHandler: OnboardingPermissionHandling, @unchecked Sendable {
    class MockEvent: EventIdentifier {
        let eventName: String = ""

        let uniqueIdentifier: Int32
        init(uniqueIdentifier: Int32) {
            self.uniqueIdentifier = uniqueIdentifier
        }
    }

    func screenViewEvent() -> any EventIdentifier {
        MockEvent(uniqueIdentifier: 0)
    }
    
    func enablePermissionAnalyticsEvent() -> any EventIdentifier {
        MockEvent(uniqueIdentifier: 1)
    }
    
    func skipPermissionAnalyticsEvent() -> any EventIdentifier {
        MockEvent(uniqueIdentifier: 2)
    }
    
    func permissionResultAnalyticsEvent() async -> (any EventIdentifier)? {
        requestPermissionValue ? MockEvent(uniqueIdentifier: 3) : nil
    }
    
    private let requestPermissionValue: Bool
    init(requestPermissionValue: Bool) {
        self.requestPermissionValue = requestPermissionValue
    }
    func requestPermission() async -> Bool {
        requestPermissionValue
    }
}
