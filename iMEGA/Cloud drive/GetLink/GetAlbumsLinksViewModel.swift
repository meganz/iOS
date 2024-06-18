import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation

final class GetAlbumsLinkViewModel: GetLinkViewModelType {
    
    let isMultiLink: Bool = true
    var invokeCommand: ((GetLinkViewModelCommand) -> Void)?
    var numberOfSections: Int { sectionViewModels.count }
    
    private let albums: [AlbumEntity]
    private let shareAlbumUseCase: any ShareAlbumUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var sectionViewModels = [GetLinkSectionViewModel]()
    private var albumLinks: [HandleEntity: String]?
    private var loadingTask: Task<Void, Never>?
    private typealias Continuation = AsyncStream<SensitiveContentAcknowledgementStatus>.Continuation

    init(albums: [AlbumEntity],
         shareAlbumUseCase: some ShareAlbumUseCaseProtocol,
         sectionViewModels: [GetLinkSectionViewModel],
         tracker: some AnalyticsTracking,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.albums = albums
        self.shareAlbumUseCase = shareAlbumUseCase
        self.sectionViewModels = sectionViewModels
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: GetLinkAction) {
        switch action {
        case .onViewReady:
            tracker.trackAnalyticsEvent(with: MultipleAlbumLinksScreenEvent())
            updateViewConfiguration()
            loadingTask = Task { await startGetLinksCoordinatorStream() }
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
        invokeCommand?(.hideMultiLinkDescription)
    }
    
    @MainActor
    private func startGetLinksCoordinatorStream() async {
        
        let (stream, continuation) = AsyncStream.makeStream(of: SensitiveContentAcknowledgementStatus.self, bufferingPolicy: .bufferingNewest(1))
        
        continuation.yield(featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) ? .unknown : .authorized) // Set initial value
        
        for await status in stream {
            switch status {
            case .unknown:
                await determineIfAlbumsContainSensitiveNodes(continuation: continuation)
            case .notDetermined:
                showContainsSensitiveContentAlert(continuation: continuation)
            case .noSensitiveContent:
                await loadLinksForAlbums(continuation: continuation)
            case .authorized:
                invokeCommand?(.showHud(.status(Strings.Localizable.generatingLinks)))
                await loadLinksForAlbums(continuation: continuation)
            case .denied:
                invokeCommand?(.dismiss)
            }
        }
    }
    
    @MainActor
    private func loadLinksForAlbums(continuation: Continuation) async {
                
        guard !Task.isCancelled else {
            return
        }
        
        let sharedLinks = await shareAlbumUseCase.shareLink(forAlbums: albums)
        
        guard !Task.isCancelled else {
            return
        }
        
        albumLinks = sharedLinks
        updateLinkRows(forAlbumLinks: sharedLinks)
        continuation.finish()
    }
        
    private func determineIfAlbumsContainSensitiveNodes(continuation: Continuation) async {
        let excludeExportedAlbums = albums.filter { !$0.isLinkShared }
                                                   
        guard excludeExportedAlbums.isNotEmpty else {
            continuation.yield(.authorized)
            return
        }

        invokeCommand?(.showHud(.status(Strings.Localizable.generatingLinks)))

        do {
            let result = try await shareAlbumUseCase.doesAlbumsContainSensitiveElement(for: excludeExportedAlbums)
            continuation.yield(result ? .notDetermined : .noSensitiveContent)
        } catch {
            MEGALogError("[\(type(of: self))]: determineIfAlbumsContainSensitiveNodes returned \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func showContainsSensitiveContentAlert(continuation: Continuation) {
        
        invokeCommand?(.dismissHud)
        let message = if albums.count > 1 {
            Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.Message.multi
        } else {
            Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.Message.single
        }
        let alertModel = AlertModel(
            title: Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.title,
            message: message,
            actions: [
                .init(title: Strings.Localizable.cancel, style: .cancel, handler: {
                    continuation.yield(.denied)
                }),
                .init(title: Strings.Localizable.continue, style: .default, isPreferredAction: true, handler: {
                    continuation.yield(.authorized)
                })
            ])
        
        invokeCommand?(.showAlert(alertModel))
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
        invokeCommand?(.showHud(.custom(UIImage.copy,
                                        Strings.Localizable.SharedItems.GetLink.linkCopied(albumLinks.count))))
    }
    
    private func copyLinkToPasteBoard(at indexPath: IndexPath) {
        guard let sectionItemHandle = sectionViewModels[safe: indexPath.section]?.itemHandle,
              let albumLinks,
              let link = albumLinks[sectionItemHandle] else {
            return
        }
        invokeCommand?(.addToPasteBoard(link))
        invokeCommand?(.showHud(.custom(UIImage.copy,
                                        Strings.Localizable.SharedItems.GetLink.linkCopied(1))))
    }
}
