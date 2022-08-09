import Foundation

enum TermsAndPoliciesAction: ActionType {
    case showPrivacyPolicy
    case showCookiePolicy
    case showTermsOfService
}

final class TermsAndPoliciesViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        
    }
    
    private let router: TermsAndPoliciesRouterProtocol
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    
    init(router: TermsAndPoliciesRouterProtocol) {
        self.router = router
    }
        
    func dispatch(_ action: TermsAndPoliciesAction) {
        switch action {
        case .showPrivacyPolicy:
            router.didTap(on: .showPrivacyPolicy)
            
        case .showCookiePolicy:
            router.didTap(on: .showCookiePolicy)
            
        case .showTermsOfService:
            router.didTap(on: .showTermsOfService)
        }
    }
}
