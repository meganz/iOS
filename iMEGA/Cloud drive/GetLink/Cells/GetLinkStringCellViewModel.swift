import Foundation
import MEGAPresentation

enum GetLinkStringCellAction: ActionType {
    case onViewReady
}

final class GetLinkStringCellViewModel: GetLinkCellViewModelType {
    enum Command: CommandType, Equatable {
        case configView(title: String, leftImage: UIImage, isRightImageViewHidden: Bool)
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    let type: GetLinkCellType
    private var title: String
    private let leftImage: UIImage
    private let isRightImageViewHidden: Bool
    
    init(type: GetLinkCellType, title: String, leftImage: UIImage, isRightImageViewHidden: Bool) {
        self.type = type
        self.title = title
        self.leftImage = leftImage
        self.isRightImageViewHidden = isRightImageViewHidden
    }
    
    func dispatch(_ action: GetLinkStringCellAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(title: title, leftImage: leftImage,
                                       isRightImageViewHidden: isRightImageViewHidden))
        }
    }
}

extension GetLinkStringCellViewModel {
    convenience init(link: String) {
        self.init(type: .link, title: link, leftImage: Asset.Images.GetLinkView.linkGetLink.image,
                  isRightImageViewHidden: true)
    }
    
    convenience init(key: String) {
        self.init(type: .key, title: key, leftImage: Asset.Images.Generic.iconKeyOnly.image,
                  isRightImageViewHidden: true)
    }
}
