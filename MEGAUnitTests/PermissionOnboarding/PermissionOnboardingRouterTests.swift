@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAssets
import MEGAL10n
import MEGAPermissionsMock
import SwiftUI
import Testing

@Suite("Permission Onboarding Router Tests")
struct PermissionOnboardingRouterTests {
    class MockViewController: UIViewController {
        private(set) var presentCallCount = 0
        private(set) var dismissCallCount = 0
        var presentedVC: UIViewController?

        override func present(_ viewControllerToPresent: UIViewController,
                              animated flag: Bool,
                              completion: (() -> Void)? = nil) {
            presentCallCount += 1
            presentedVC = viewControllerToPresent
        }

        override func dismiss(animated flag: Bool,
                              completion: (() -> Void)? = nil) {
            dismissCallCount += 1
        }
    }

    struct TestCase {
        struct ViewModelOutput {
            let image: Image
            let title: String
            let description: String
            let note: String?
            let primaryButton: String
            let secondaryButton: String
        }
        let permissionType: PermissionOnboardingRouter.PermissionOnboardingType
        let PermissionHandlerKeyPath: ReferenceWritableKeyPath<MockDevicePermissionHandler, Bool>
        let shouldAskPermission: Bool
        let viewModelOutput: ViewModelOutput
        static let notifications = TestCase(
            permissionType: .notifications,
            PermissionHandlerKeyPath: \MockDevicePermissionHandler.shouldAskForNotificationPermissionsValueToReturn,
            shouldAskPermission: true,
            viewModelOutput: ViewModelOutput(
                image: MEGAAssets.Image.notificationCta,
                title: Strings.Localizable.Onboarding.Cta.Notifications.title,
                description: Strings.Localizable.Onboarding.Cta.Notifications.explanation,
                note: nil,
                primaryButton: Strings.Localizable.Onboarding.Cta.Notifications.Buttons.enable,
                secondaryButton: Strings.Localizable.Onboarding.Cta.Notifications.Buttons.skip
            )
        )

        static let cameraBackups = TestCase(
            permissionType: .cameraBackups,
            PermissionHandlerKeyPath: \MockDevicePermissionHandler.shouldAskForPhotosPermissions,
            shouldAskPermission: true,
            viewModelOutput: ViewModelOutput(
                image: MEGAAssets.Image.cameraBackupsCta,
                title: Strings.Localizable.Onboarding.Cta.CameraBackups.title,
                description: Strings.Localizable.Onboarding.Cta.CameraBackups.explanation,
                note: Strings.Localizable.Onboarding.Cta.CameraBackups.note,
                primaryButton: Strings.Localizable.Onboarding.Cta.CameraBackups.Buttons.enable,
                secondaryButton: Strings.Localizable.Onboarding.Cta.CameraBackups.Buttons.skip
            )
        )
    }

    @MainActor
    @Test(
        "when permission can be requested, should show PermissionOnboardingView with correct view model data and output",
        arguments: [
            (TestCase.notifications, true),
            (.notifications, false),
            (.cameraBackups, true),
            (.cameraBackups, false)
            ]
    )
    func testShouldAskForPermissions(testCase: TestCase, output: Bool) async throws {
        let window = UIWindow()
        let handler = MockDevicePermissionHandler()
        handler[keyPath: testCase.PermissionHandlerKeyPath] = testCase.shouldAskPermission
        let sut = PermissionOnboardingRouter(
            permissionsHandler: handler
        )

        let startTask = Task.detached {
            await sut.start(window: window, permissionType: testCase.permissionType)
        }
        try await Task.sleep(nanoseconds: 100_000_000)

        let hosted = try #require(
            window.rootViewController as? UIHostingController<PermissionOnboardingView>
        )
        let viewModel = hosted.rootView.viewModel

        #expect(viewModel.image == testCase.viewModelOutput.image)
        #expect(viewModel.title == testCase.viewModelOutput.title)
        #expect(viewModel.description == testCase.viewModelOutput.description)
        #expect(viewModel.note == testCase.viewModelOutput.note)
        #expect(viewModel.primaryButtonTitle == testCase.viewModelOutput.primaryButton)
        #expect(viewModel.secondaryButtonTitle == testCase.viewModelOutput.secondaryButton)

        viewModel.routeTo(.finished(result: output))
        #expect(await startTask.value == output)
    }

    @MainActor
    @Test(
        "when permission can NOT be requested, should not show anything",
        arguments: [TestCase.notifications, .cameraBackups]
    )
    func testShouldNotAskForPermissions(testCase: TestCase) async throws {
        let window = UIWindow()
        let handler = MockDevicePermissionHandler()
        handler[keyPath: testCase.PermissionHandlerKeyPath] = false
        let sut = PermissionOnboardingRouter(
            permissionsHandler: handler
        )

        let startTask = Task.detached {
            await sut.start(window: window, permissionType: testCase.permissionType)
        }
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(window.rootViewController == nil)

        #expect(await startTask.value == nil)
    }
}
