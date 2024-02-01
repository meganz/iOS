import MEGADomain
import MEGAL10n

// This delegate object is used by the new cloud drive (NodeBrowserView) to
// handle display related context menu actions
// Classes below, similarly are supposed to handle other sections of the context menu such
// as related to uploading and rubbish bin
final class DisplayMenuDelegateHandler: DisplayMenuDelegate {
    
    var presenterViewController: UIViewController?
    var refreshMenu: (() -> Void)?
    
    let toggleSelection: () -> Void
    let changeViewMode: (ViewModePreferenceEntity) -> Void
    let rubbishBinUseCase: any RubbishBinUseCaseProtocol
    
    init(
        rubbishBinUseCase: some RubbishBinUseCaseProtocol,
        toggleSelection: @escaping () -> Void,
        changeViewMode: @escaping (ViewModePreferenceEntity) -> Void
    ) {
        self.rubbishBinUseCase = rubbishBinUseCase
        self.toggleSelection = toggleSelection
        self.changeViewMode = changeViewMode
    }
    
    func confirmClearRubbishBin(presenter: UIViewController) {
        let alertController = UIAlertController(title: Strings.Localizable.emptyRubbishBinAlertTitle, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default) { [weak self] _ in
            self?.rubbishBinUseCase.cleanRubbishBin()
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
        assert(false, "not implemented yet, scheduled to be done in [FM-1776]")
    }
}

final class UploadAddMenuDelegateHandler: UploadAddMenuDelegate {
    func uploadAddMenu(didSelect action: MEGADomain.UploadAddActionEntity) {
        
    }
}

// Implementing of the selection of nodes
// will be implemented here [FM-1463]
final class MediaContentDelegate: MediaDiscoveryContentDelegate {
    
    var isMediaDiscoverySelectionHandler: ((_ isHidden: Bool) -> Void)?
    
    func selectedPhotos(selected: [MEGADomain.NodeEntity], allPhotos: [MEGADomain.NodeEntity]) {
        // Connect select photos action
    }
    
    func isMediaDiscoverySelection(isHidden: Bool) {
        isMediaDiscoverySelectionHandler?(isHidden)
    }
    
    func mediaDiscoverEmptyTapped(menuAction: EmptyMediaDiscoveryContentMenuAction) {
        // Connect empty tapped action
    }
}
