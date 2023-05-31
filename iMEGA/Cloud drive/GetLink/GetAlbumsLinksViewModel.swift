import Foundation
import MEGAPresentation
import MEGADomain

final class GetAlbumsLinkViewModel: GetLinkViewModelType {
    var invokeCommand: ((GetLinkViewModelCommand) -> Void)?
    
    private let albums: [AlbumEntity]
    private let shareAlbumUseCase: ShareAlbumUseCaseProtocol
    private var sectionViewModels = [GetLinkSectionViewModel]()
    private var albumLinks: [HandleEntity: String]?
    private var loadingTask: Task<Void, Never>?
    
    let isMultiLink: Bool = true
    
    var numberOfSections: Int {
        sectionViewModels.count
    }
    
    init(albums: [AlbumEntity], shareAlbumUseCase: ShareAlbumUseCaseProtocol,
         sectionViewModels: [GetLinkSectionViewModel]) {
        self.albums = albums
        self.shareAlbumUseCase = shareAlbumUseCase
        self.sectionViewModels = sectionViewModels
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: GetLinkAction) {
        switch action {
        case .onViewReady:
            updateViewConfiguration()
            loadLinksForAlbums()
        case .onViewWillDisappear:
            cancelLoadingTask()
        case .shareLink(sender: let sender):
            shareLink(sender: sender)
        case .copyLink:
            copyLinksToPasteBoard()
        case .didSelectRow(let indexPath):
            copyLinkToPasteBoard(at: indexPath)
        default:
            break
        }
    }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        sectionViewModels[safe: section]?.cellViewModels.count ?? 0
    }
    
    func cellViewModel(indexPath: IndexPath) -> (any GetLinkCellViewModelType)? {
        sectionViewModels[safe: indexPath.section]?.cellViewModels[safe: indexPath.row]
    }
    
    func sectionType(forSection section: Int) -> GetLinkTableViewSection? {
        guard let section = sectionViewModels[safe: section] else {
            return nil
        }
        return section.sectionType
    }
    
    // MARK: - Private
    private func updateViewConfiguration() {
        let itemCount = albums.count
        let title = albums.contains(where: { $0.isLinkShared }) ? Strings.Localizable.General.MenuAction.ManageLink.title(itemCount) :
        Strings.Localizable.General.MenuAction.ShareLink.title(itemCount)
        invokeCommand?(.configureView(title: title,
                                      isMultilink: isMultiLink,
                                      shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(itemCount)))
    }
    
    private func loadLinksForAlbums() {
        invokeCommand?(.showHud(.status(Strings.Localizable.generatingLinks)))
        loadingTask = Task { [weak self] in
            guard let self else { return }
            defer { cancelLoadingTask() }
            
            let sharedLinks = await shareAlbumUseCase.shareLink(forAlbums: albums)
            guard !Task.isCancelled else { return }
            
            albumLinks = sharedLinks
            await updateLinkRows(forAlbumLinks: sharedLinks)
        }
    }
    
    private func cancelLoadingTask() {
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    @MainActor
    private func updateLinkRows(forAlbumLinks sharedLinks: [HandleEntity: String]) {
        let rowsToReload = sharedLinks.compactMap { albumId, link in
            updateLinkRow(link: link, albumId: albumId)
        }.sorted()
        guard rowsToReload.isNotEmpty else {
            invokeCommand?(.dismissHud)
            return
        }
        invokeCommand?(.reloadRows(rowsToReload))
        invokeCommand?(.enableLinkActions)
        invokeCommand?(.dismissHud)
    }
    
    private func updateLinkRow(link: String, albumId: HandleEntity) -> IndexPath? {
        guard let sectionIndex = sectionViewModels.firstIndex(where: { $0.itemHandle == albumId }),
              let rowIndex = sectionViewModels[safe: sectionIndex]?.cellViewModels.firstIndex(where: { $0 is GetLinkStringCellViewModel }) else {
            return nil
        }
        sectionViewModels[sectionIndex].cellViewModels[rowIndex] = GetLinkStringCellViewModel(link: link)
        return IndexPath(row: rowIndex, section: sectionIndex)
    }
    
    private func shareLink(sender: UIBarButtonItem) {
        guard let albumLinks else { return }
        let joinedLinks = albumLinks.values.joined(separator: "\n")
        invokeCommand?(.showShareActivity(sender: sender,
                                          link: joinedLinks,
                                          key: nil))
    }
    
    private func copyLinksToPasteBoard() {
        guard let albumLinks else { return }
        let joinedLinks = albumLinks.values.joined(separator: " ")
        invokeCommand?(.addToPasteBoard(joinedLinks))
        invokeCommand?(.showHud(.custom(Asset.Images.NodeActions.copy.image,
                                        Strings.Localizable.linksCopiedToClipboard)))
    }
    
    private func copyLinkToPasteBoard(at indexPath: IndexPath) {
        guard let sectionItemHandle = sectionViewModels[safe: indexPath.section]?.itemHandle,
              let albumLinks,
              let link = albumLinks[sectionItemHandle] else {
            return
        }
        invokeCommand?(.addToPasteBoard(link))
        invokeCommand?(.showHud(.custom(Asset.Images.NodeActions.copy.image,
                                        Strings.Localizable.linkCopiedToClipboard)))
    }
}
