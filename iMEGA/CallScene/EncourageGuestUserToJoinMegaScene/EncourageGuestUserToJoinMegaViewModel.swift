import Foundation
import MEGAPresentation

enum EncourageGuestUserToJoinMegaViewAction: ActionType {
    case didCreateAccountButton
    case didTapCloseButton
}

struct EncourageGuestUserToJoinMegaViewModel: ViewModelType {
    
    enum Command: CommandType {}
    
    // MARK: - Private properties
    private let router: EncourageGuestUserToJoinMegaRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: EncourageGuestUserToJoinMegaRouting) {
        self.router = router
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: EncourageGuestUserToJoinMegaViewAction) {
        switch action {
        case .didCreateAccountButton:
            router.createAccount()
        case .didTapCloseButton:
            router.dismiss()
        }
    }
    
}
