@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

struct PermissionOnboardingViewModelTests {

    @Test("On primary button tap should change route to .finished with correct result",
    arguments: [true, false])
    func primaryButtonTap(permissionGranted: Bool) async {
        let permissionRequester = MockPermissionOnboardingRequester(requestPermissionValue: permissionGranted)
        let sut = PermissionOnboardingViewModel(
            image: .info,
            title: "title",
            description: "description",
            note: nil,
            primaryButtonTitle: "primaryButtonTitle",
            secondaryButtonTitle: "secondaryButtonTitle",
            permissionRequester: permissionRequester
        )

        await sut.onPrimaryButtonTap()
        #expect(sut.route == .finished(result: permissionGranted))
    }

    @Test("On secondary button tap should change route to ,skipped")
    func secondaryButtonTap() async {
        let permissionRequester = MockPermissionOnboardingRequester(requestPermissionValue: false)
        let sut = PermissionOnboardingViewModel(
            image: .info,
            title: "title",
            description: "description",
            note: nil,
            primaryButtonTitle: "primaryButtonTitle",
            secondaryButtonTitle: "secondaryButtonTitle",
            permissionRequester: permissionRequester
        )

        await sut.onSecondaryButtonTap()
        #expect(sut.route == .skipped)
    }
}

private final class MockPermissionOnboardingRequester: PermissionOnboardingRequesting, @unchecked Sendable {
    private let requestPermissionValue: Bool
    init(requestPermissionValue: Bool) {
        self.requestPermissionValue = requestPermissionValue
    }
    func requestPermission() async -> Bool {
        requestPermissionValue
    }
}
