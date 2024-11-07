import MEGAPresentation

enum GetLinkAccessInfoCellAction: ActionType {
    case onViewReady
}

final class GetLinkAccessInfoCellViewModel: ViewModelType, GetLinkCellViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String)
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    let type: GetLinkCellType
    private let title: String
    
    init(type: GetLinkCellType, title: String) {
        self.type = type
        self.title = title
    }
    
    func dispatch(_ action: GetLinkAccessInfoCellAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(title: title))
        }
    }
}

extension GetLinkAccessInfoCellViewModel {
    
    convenience init(title: String) {
        self.init(type: .linkAccess, title: title)
    }
}
