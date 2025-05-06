@testable import MEGA

final class MockLoginRouter: LoginRouterProtocol {
    enum Invocation {
        case showSignUp
        case showLogin
        case dismiss
        case showPermissionLoading
    }
    private(set) var invocations: [Invocation] = []
    nonisolated init() {}
    
    func build() -> UIViewController {
        .init()
    }
    
    func start() {
        showLogin()
    }
    
    func showSignUp() {
        invocations.append(.showSignUp)
    }
    
    func showLogin() {
        invocations.append(.showLogin)
    }
    
    func dismiss(completion: (() -> Void)?) {
        invocations.append(.dismiss)
        completion?()
    }
    
    func showPermissionLoading() {
        invocations.append(.showPermissionLoading)
    }
}
