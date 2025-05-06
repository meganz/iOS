@testable import MEGA
import Testing

struct CreateAccountRoutingViewModelTests {

    @Test("Ensure that logged in set root view controller to permission app launcher")
    @MainActor
    func loggedIn() async throws {
        let router = MockLoginRouter()
        let sut = CreateAccountRoutingViewModelTests
            .makeSUT(router: router)
        
        try await sleep()
        
        sut.createAccountViewModel.route = .loggedIn
        
        try await sleep()
        
        #expect(router.invocations == [.showPermissionLoading])
    }
    
    @Test("Ensure dismiss called on router")
    @MainActor
    func dismiss() async throws {
        let router = MockLoginRouter()
        let sut = CreateAccountRoutingViewModelTests
            .makeSUT(router: router)
        
        try await sleep()
        
        sut.createAccountViewModel.route = .dismissed
        
        try await sleep()
        
        #expect(router.invocations == [.dismiss])
    }
    
    @Test("Ensure login route calls router to dismiss and show login")
    @MainActor
    func login() async throws {
        let router = MockLoginRouter()
        let sut = CreateAccountRoutingViewModelTests
            .makeSUT(router: router)
        
        try await sleep()
        
        sut.createAccountViewModel.route = .login
        
        try await sleep()
        
        #expect(router.invocations == [.dismiss, .showLogin])
    }
    
    private func sleep() async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    @MainActor
    private static func makeSUT(
        router: some LoginRouterProtocol = MockLoginRouter()
    ) -> CreateAccountRoutingViewModel {
        .init(router: router)
    }
}
