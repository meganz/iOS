@testable import MEGA
import Testing

struct LoginRoutingViewModelTests {

    @Test("Ensure that logged in set root view controller to permission app launcher")
    @MainActor
    func loggedIn() async throws {
        let router = MockLoginRouter()
        let sut = LoginRoutingViewModelTests
            .makeSUT(router: router)
        
        try await wait()
        
        sut.loginViewModel.route = .loggedIn
        
        try await wait()
        
        #expect(router.invocations == [.showPermissionLoading])
    }
    
    @Test("Ensure dismiss called on router")
    @MainActor
    func dismiss() async throws {
        let router = MockLoginRouter()
        let sut = LoginRoutingViewModelTests
            .makeSUT(router: router)
        
        try await wait()
        
        sut.loginViewModel.route = .dismissed
        
        try await wait()
        
        #expect(router.invocations == [.dismiss])
    }
    
    @Test("Ensure signup route calls router to dismiss and show sign up")
    @MainActor
    func signUp() async throws {
        let router = MockLoginRouter()
        let sut = LoginRoutingViewModelTests
            .makeSUT(router: router)
        
        try await wait()
        
        sut.loginViewModel.route = .signUp
        
        try await wait()
        
        #expect(router.invocations == [.dismiss, .showSignUp])
    }
    
    private func wait() async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    @MainActor
    private static func makeSUT(
        router: some LoginRouterProtocol = MockLoginRouter()
    ) -> LoginRoutingViewModel {
        .init(router: router)
    }
}
