import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n

final class GetCollectionsLinkViewModel: GetLinkViewModelType {
    
    let isMultiLink: Bool = true
    var invokeCommand: ((GetLinkViewModelCommand) -> Void)?
    var numberOfSections: Int { sectionViewModels.count }
    
    private let setEntities: [SetEntity]
    private let shareCollectionUseCase: any ShareCollectionUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private var sectionViewModels = [GetLinkSectionViewModel]()
    private var albumLinks: [SetIdentifier: String]?
    private var loadingTask: Task<Void, Never>?
    private typealias Continuation = AsyncStream<SensitiveContentAcknowledgementStatus>.Continuation
    
    deinit {
        loadingTask?.cancel()
    }

    init(setEntities: [SetEntity],
         shareCollectionUseCase: some ShareCollectionUseCaseProtocol,
         sectionViewModels: [GetLinkSectionViewModel],
         tracker: some AnalyticsTracking,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        self.setEntities = setEntities
        self.shareCollectionUseCase = shareCollectionUseCase
        self.sectionViewModels = sectionViewModels
        self.tracker = tracker
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: GetLinkAction) {
        switch action {
        case .onViewReady:
            trackOnViewReadyAnalyticsEvent()
            updateViewConfiguration()
        case .onViewDidAppear where loadingTask == nil:
            loadingTask = Task { await startGetLinksCoordinatorStream() }
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
    
    private func trackOnViewReadyAnalyticsEvent() {
        guard let setType = setEntities.map(\.setType).first else { return }
        switch setType {
        case .album:
            tracker.trackAnalyticsEvent(with: MultipleAlbumLinksScreenEvent())
        case .playlist, .invalid:
            break
        }
    }
    
    private func updateViewConfiguration() {
        let itemCount = setEntities.count
        let title = setEntities.contains(where: { $0.isExported }) ? Strings.Localizable.General.MenuAction.ManageLink.title(itemCount) :
        Strings.Localizable.General.MenuAction.ShareLink.title(itemCount)
        invokeCommand?(.configureView(title: title,
                                      isMultilink: isMultiLink,
                                      shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(itemCount)))
        invokeCommand?(.hideMultiLinkDescription)
    }
    
    @MainActor
    private func startGetLinksCoordinatorStream() async {
        
        let (stream, continuation) = AsyncStream.makeStream(of: SensitiveContentAcknowledgementStatus.self, bufferingPolicy: .bufferingNewest(1))
        
        continuation.yield(remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) ? .unknown : .authorized) // Set initial value
        
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
        
        let sharedLinks = await shareCollectionUseCase.shareLink(forCollections: setEntities)
        
        guard !Task.isCancelled else {
            return
        }
        
        updateLinkRows(forAlbumLinks: sharedLinks)
        continuation.finish()
    }
        
    private func determineIfAlbumsContainSensitiveNodes(continuation: Continuation) async {
        let excludeExportedAlbums = setEntities.filter { !$0.isExported }
                                                   
        guard excludeExportedAlbums.isNotEmpty else {
            continuation.yield(.authorized)
            return
        }

        invokeCommand?(.showHud(.status(Strings.Localizable.generatingLinks)))

        do {
            let result = try await shareCollectionUseCase.doesCollectionsContainSensitiveElement(for: excludeExportedAlbums)
            continuation.yield(result ? .notDetermined : .noSensitiveContent)
        } catch {
            MEGALogError("[\(type(of: self))]: determineIfAlbumsContainSensitiveNodes returned \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func showContainsSensitiveContentAlert(continuation: Continuation) {
        
        invokeCommand?(.dismissHud)
        let message = if setEntities.count > 1 {
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

    @MainActor
    private func updateLinkRows(forAlbumLinks sharedLinks: [SetIdentifier: String]) {
        let rowsToReload = sharedLinks.compactMap { albumId, link in
            updateLinkRow(link: link, albumId: albumId)
        }.sorted()
        guard rowsToReload.isNotEmpty else {
            invokeCommand?(.dismissHud)
            return
        }
        albumLinks = sharedLinks
        invokeCommand?(.reloadRows(rowsToReload))
        invokeCommand?(.enableLinkActions)
        invokeCommand?(.dismissHud)
    }
    
    private func updateLinkRow(link: String, albumId: SetIdentifier) -> IndexPath? {
        guard let sectionIndex = sectionViewModels.firstIndex(where: { $0.setIdentifier == albumId }),
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
        guard let sectionItemHandle = sectionViewModels[safe: indexPath.section]?.setIdentifier,
              let albumLinks,
              let link = albumLinks[sectionItemHandle] else {
            return
        }
        invokeCommand?(.addToPasteBoard(link))
        invokeCommand?(.showHud(.custom(UIImage.copy,
                                        Strings.Localizable.SharedItems.GetLink.linkCopied(1))))
    }
}
