@testable import MEGA
import MEGAAuthentication
import MEGASwift
import Testing

struct OnboardingRoutingViewModelTests {

    @Test("when routing is logged in should set permission app launcher as root view")
    @MainActor
    func loggedIn() async throws {
        let router = MockPermissionAppLaunchRouter()
        @Atomic var confirmAccount = false
        let sut = OnboardingRoutingViewModelTests.makeSUT { hasConfirmedAccount in
            $confirmAccount.mutate {
                $0 = hasConfirmedAccount
            }
            router.setRootViewController(shouldShowLoadingScreen: true)
        }

        try await Task.sleep(nanoseconds: 100_000_000)
        
        sut.onboardingViewModel.route = .loggedIn
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(router.setRootViewControllerCalled == 1)
        #expect(confirmAccount == false)
    }

    @Test(
        "when account is confirmed should show subscription page",
        .disabled("Disabled due to flakiness")
    )
    @MainActor
    func accountConfirmation() async throws {
        let accountConfirmationUseCase = MockAccountConfirmationUseCase()
        @Atomic var confirmAccount = false
        let sut = OnboardingRoutingViewModelTests.makeSUT(
            accountConfirmationUseCase: accountConfirmationUseCase
        ) { hasConfirmedAccount in
            $confirmAccount.mutate {
                $0 = hasConfirmedAccount
            }
        }

        try await waitUntil(await accountConfirmationUseCase.continuation == nil)
        await accountConfirmationUseCase.continuation?.resume()

        sut.onboardingViewModel.route = .loggedIn

        try await waitUntil(confirmAccount == true)
        #expect(confirmAccount == true)
    }

    @MainActor
    private static func makeSUT(
        accountConfirmationUseCase: some AccountConfirmationUseCaseProtocol = MockAccountConfirmationUseCase(),
        onLoginSuccess: @escaping OnboardingRoutingViewModel.LoginSuccess = { _ in }
    ) -> OnboardingRoutingViewModel {
        .init(
            accountConfirmationUseCase: accountConfirmationUseCase,
            onLoginSuccess: onLoginSuccess
        )
    }

    private func waitUntil(
        timeout: TimeInterval = 2.0,
        _ condition: @Sendable @autoclosure @escaping () async -> Bool
    ) async throws {
        try await withTimeout(seconds: timeout) {
            while await condition() {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
    }
}

private final class MockPermissionAppLaunchRouter: PermissionAppLaunchRouterProtocol {
    private(set) var setRootViewControllerCalled = 0

    nonisolated init() {}
    
    func setRootViewController(shouldShowLoadingScreen: Bool) {
        setRootViewControllerCalled += 1
    }
}

private actor MockAccountConfirmationUseCase: AccountConfirmationUseCaseProtocol {
    private(set) var continuation: CheckedContinuation<Void, Never>?

    func resendSignUpLink(withEmail email: String, name: String) async throws {}

    nonisolated func cancelCreateAccount() {}

    func waitForAccountConfirmationEvent() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func verifyAccount(with confirmationLinkUrl: String) async throws -> Bool { return false}
}
