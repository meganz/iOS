import Foundation

enum ___VARIABLE_sceneName:identifier___Action: ActionType {
    case onViewLoaded
}

protocol ___VARIABLE_sceneName:identifier___ViewRouting: Routing {
//    func ...()
}

final class ___VARIABLE_sceneName:identifier___ViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case commandExample
//        case ...
    }
    
    // MARK: - Private properties
    private let router: ___VARIABLE_sceneName:identifier___ViewRouting
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: ___VARIABLE_sceneName:identifier___ViewRouting) {
        self.router = router
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: ___VARIABLE_sceneName:identifier___Action) {
        switch action {
        case .onViewLoaded:
            invokeCommand?(.commandExample)
        }
    }
}
