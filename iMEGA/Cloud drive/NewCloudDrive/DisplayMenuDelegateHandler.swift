import MEGADomain
import MEGAL10n
// This delegate object is used by the new cloud drive (NodeBrowserView) to
// handle display related context menu actions
// Classes below, similarly are supposed to handle other sections of the context menu such
// as related to uploading and rubbish bin
final class DisplayMenuDelegateHandler: DisplayMenuDelegate, RefreshMenuTriggering {
    
    var presenterViewController: UIViewController?
    var refreshMenu: (() -> Void)?
    
    let toggleSelection: () -> Void
    let changeViewMode: (ViewModePreferenceEntity) -> Void
    let changeSortOrder: (SortOrderType) -> Void
    let rubbishBinUseCase: any RubbishBinUseCaseProtocol
    
    init(
        rubbishBinUseCase: some RubbishBinUseCaseProtocol,
        toggleSelection: @escaping () -> Void,
        changeViewMode: @escaping (ViewModePreferenceEntity) -> Void,
        changeSortOrder: @escaping (SortOrderType) -> Void
    ) {
        self.rubbishBinUseCase = rubbishBinUseCase
        self.toggleSelection = toggleSelection
        self.changeViewMode = changeViewMode
        self.changeSortOrder = changeSortOrder
    }
    
    func confirmClearRubbishBin(presenter: UIViewController) {
        let alertController = UIAlertController(title: Strings.Localizable.emptyRubbishBinAlertTitle, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default) { [weak self] _ in
            SVProgressHUD.setDefaultMaskType(.none)
            SVProgressHUD.show()
            self?.rubbishBinUseCase.cleanRubbishBin {
                Task { @MainActor in
                    SVProgressHUD.dismiss()
                }
            }
        })
        
        presenter.present(alertController, animated: true, completion: nil)
    }
    
    func displayMenu(
        didSelect action: DisplayActionEntity,
        needToRefreshMenu: Bool
    ) {
        switch action {
        case .select:
            toggleSelection()
        case .thumbnailView:
            changeViewMode(.thumbnail)
        case .listView:
            changeViewMode(.list)
        case .clearRubbishBin:
            if let presenterViewController {
                confirmClearRubbishBin(presenter: presenterViewController)
            }
        case .mediaDiscovery:
            changeViewMode(.mediaDiscovery)
        default:
            break
        }
        
        if needToRefreshMenu {
            refreshMenu?()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        changeSortOrder(sortType)
    }
}
