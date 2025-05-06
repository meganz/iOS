@testable import MEGA
import Testing

struct OnboardingRoutingViewModelTests {

    @Test("when routing is logged in should set permission app launcher as root view")
    @MainActor
    func loggedIn() async throws {
        let router = MockPermissionAppLaunchRouter()
        let sut = OnboardingRoutingViewModelTests.makeSUT(
            permissionAppLaunchRouter: router)
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        sut.onboardingViewModel.route = .loggedIn
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(router.setRootViewControllerCalled == 1)
    }

    @MainActor
    private static func makeSUT(
        permissionAppLaunchRouter: some PermissionAppLaunchRouterProtocol = MockPermissionAppLaunchRouter()
    ) -> OnboardingRoutingViewModel {
        .init(permissionAppLaunchRouter: permissionAppLaunchRouter)
    }
}

private final class MockPermissionAppLaunchRouter: PermissionAppLaunchRouterProtocol {
    private(set) var setRootViewControllerCalled = 0
    
    nonisolated init() {}
    
    func setRootViewController() {
        setRootViewControllerCalled += 1
    }
}
