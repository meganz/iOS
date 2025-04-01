import Foundation
import MEGAAppPresentation
import MEGADomain

enum GetLinkAction: ActionType {
    case onViewReady
    case onViewDidAppear
    case onViewWillDisappear
    case switchToggled(indexPath: IndexPath, isOn: Bool)
    case shareLink(sender: UIBarButtonItem)
    case copyLink
    case copyKey
    case didSelectRow(indexPath: IndexPath)
}

enum GetLinkViewModelCommand: CommandType {
    case configureView(title: String, isMultilink: Bool, shareButtonTitle: String)
    case enableLinkActions
    case reloadSections(IndexSet)
    case reloadRows([IndexPath])
    case deleteSections(IndexSet)
    case insertSections(IndexSet)
    case configureToolbar(isDecryptionKeySeperate: Bool)
    case showHud(_ messageType: MessageType)
    case dismissHud
    case addToPasteBoard(String)
    case showShareActivity(sender: UIBarButtonItem, link: String, key: String?)
    case hideMultiLinkDescription
    case showAlert(AlertModel)
    case dismiss
    case processNodes
    
    enum MessageType: Equatable {
        case status(String)
        case custom(UIImage, String)
    }
}

protocol GetLinkViewModelType: ViewModelType where Command == GetLinkViewModelCommand, Action == GetLinkAction {
    var isMultiLink: Bool { get }
    var numberOfSections: Int { get }
    func numberOfRowsInSection(_ section: Int) -> Int
    func cellViewModel(indexPath: IndexPath) -> (any GetLinkCellViewModelType)?
    func sectionType(forSection section: Int) -> GetLinkTableViewSection?
}
