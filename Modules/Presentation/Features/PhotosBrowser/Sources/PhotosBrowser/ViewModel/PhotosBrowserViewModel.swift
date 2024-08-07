import Foundation
import MEGAPresentation

public enum PhotosBrowserAction: ActionType {
    case buildNavigationBar
    case buildBottomToolBar
    case onViewReady
}

public final class PhotosBrowserViewModel: ViewModelType {
    let config: PhotosBrowserConfiguration
    
    public init(config: PhotosBrowserConfiguration) {
        self.config = config
    }
    
    public enum Command: CommandType, Equatable {
        case buildBottomToolBar
        case buildNavigationBar
        case onViewReady
    }
    
    public var invokeCommand: ((Command) -> Void)?
    
    public func dispatch(_ action: PhotosBrowserAction) {
        switch action {
        case .buildNavigationBar:
            invokeCommand?(.buildNavigationBar)
        case .buildBottomToolBar:
            invokeCommand?(.buildBottomToolBar)
        case .onViewReady:
            invokeCommand?(.onViewReady)
        }
    }
}
