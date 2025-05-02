@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

struct PermissionOnboardingViewModelTests {

    @Test("On primary button tap should change route and call permissionRequester")
    func primaryButtonTap() async {
        let permissionRequester = MockPermissionOnboardingRequester()
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
        #expect(permissionRequester.requestPermissionCalls == 1)
        #expect(sut.route == .finished)
    }

    @Test("On secondary button tap should change route")
    func secondaryButtonTap() async {
        let permissionRequester = MockPermissionOnboardingRequester()
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
        #expect(permissionRequester.requestPermissionCalls == 0)
        #expect(sut.route == .finished)
    }
}

private final class MockPermissionOnboardingRequester: PermissionOnboardingRequesting, @unchecked Sendable {
    var requestPermissionCalls = 0
    func requestPermission() async {
        requestPermissionCalls += 1
    }
}
