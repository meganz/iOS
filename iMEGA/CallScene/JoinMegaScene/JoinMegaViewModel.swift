import Foundation

enum JoinMegaViewAction: ActionType {
    case didCreateAccountButton
    case didTapCloseButton
}

struct JoinMegaViewModel: ViewModelType {
    
    enum Command: CommandType {}
    
    // MARK: - Private properties
    private let router: JoinMegaRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: JoinMegaRouting) {
        self.router = router
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: JoinMegaViewAction) {
        switch action {
        case .didCreateAccountButton:
            router.createAccount()
        case .didTapCloseButton:
            router.dismiss()
        }
    }
    
}
