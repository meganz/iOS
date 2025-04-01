import Foundation
import MEGAAppPresentation

enum EncourageGuestUserToJoinMegaViewAction: ActionType, Equatable {
    case didCreateAccountButton
    case didTapCloseButton
}

struct EncourageGuestUserToJoinMegaViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {}
    
    // MARK: - Private properties
    private let router: any EncourageGuestUserToJoinMegaRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some EncourageGuestUserToJoinMegaRouting) {
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
