import Foundation
import MEGAPresentation

public enum PhotosBrowserAction: ActionType {
    case onViewReady
}

public final class PhotosBrowserViewModel: ViewModelType {
    let config: PhotosBrowserConfiguration
    
    public init(config: PhotosBrowserConfiguration) {
        self.config = config
    }
    
    public enum Command: CommandType, Equatable {
        case onViewReady
    }
    
    public var invokeCommand: ((Command) -> Void)?
    
    public func dispatch(_ action: PhotosBrowserAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.onViewReady)
        }
    }
}
