import Combine
import Foundation
import MEGAAppPresentation

public enum PhotosBrowserAction: ActionType {
    case onViewReady
}

public final class PhotosBrowserViewModel: ViewModelType {
    let config: PhotosBrowserConfiguration
    
    private var subscriptions = Set<AnyCancellable>()
    
    public init(config: PhotosBrowserConfiguration) {
        self.config = config
        
        subscribeCurrentIndexChange(with: config.library)
    }
    
    public enum Command: CommandType, Equatable {
        case onViewReady
        case onCurrentIndexChange(Int)
    }
    
    public var invokeCommand: ((Command) -> Void)?
    
    public func dispatch(_ action: PhotosBrowserAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.onViewReady)
        }
    }
    
    // MARK: - Private
    
    private func subscribeCurrentIndexChange(with library: MediaLibrary) {
        library.$currentIndex
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newIndex in
                self?.invokeCommand?(.onCurrentIndexChange(newIndex))
            }
            .store(in: &subscriptions)
    }
}
