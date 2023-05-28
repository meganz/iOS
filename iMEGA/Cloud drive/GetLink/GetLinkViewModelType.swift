import Foundation
import MEGAPresentation
import MEGADomain

enum GetLinkAction: ActionType {
    case onViewReady
    case switchToggled(indexPath: IndexPath, isOn: Bool)
}

enum GetLinkViewModelCommand: CommandType, Equatable {
    case configureView(title: String, isMultilink: Bool)
    case enableLinkActions
    case reloadSections(IndexSet)
    case reloadRows([IndexPath])
    case deleteSections(IndexSet)
    case insertSections(IndexSet)
}

protocol GetLinkViewModelType: ViewModelType where Command == GetLinkViewModelCommand, Action == GetLinkAction {
    var isMultiLink: Bool { get }
    var numberOfSections: Int { get }
    func numberOfRowsInSection(_ section: Int) -> Int
    func cellViewModel(indexPath: IndexPath) -> (any GetLinkCellViewModelType)?
    func sectionType(forSection section: Int) -> GetLinkTableViewSection?
}
