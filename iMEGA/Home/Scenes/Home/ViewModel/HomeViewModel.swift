import Foundation

enum HomeAction: ActionType {}

enum HomeCommand: CommandType, Equatable {}

final class HomeViewModel: ViewModelType {
    
    var invokeCommand: ((HomeCommand) -> Void)?
    
    func dispatch(_ action: HomeAction) {
        
    }
    
    // MARK: - Action & Command
    
    typealias Action = HomeAction
    
    typealias Command = HomeCommand
}
