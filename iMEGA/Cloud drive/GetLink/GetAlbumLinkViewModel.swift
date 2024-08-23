import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation

final class GetAlbumLinkViewModel: GetLinkViewModelType {
    var invokeCommand: ((GetLinkViewModelCommand) -> Void)?
    let isMultiLink: Bool = false
    var loadingTask: Task<Void, Never>?
    var numberOfSections: Int {
        sectionViewModels.count
    }
    
    var isDecryptingKeySeperately: Bool {
        guard let decryptCellViewModel = sectionViewModels.first(where: { $0.sectionType == .decryptKeySeparate})?.cellViewModels.first(where: { $0.type == .decryptKeySeparate }) as? GetLinkSwitchOptionCellViewModel else {
            return false
        }
        return decryptCellViewModel.isSwitchOn
    }
    
    private let album: AlbumEntity
    private let shareCollectionUseCase: any ShareCollectionUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var sectionViewModels = [GetLinkSectionViewModel]()
    private var shareLink: String?
    
    private typealias Continuation = AsyncStream<SensitiveContentAcknowledgementStatus>.Continuation
    
    deinit {
        loadingTask?.cancel()
    }
    
    init(album: AlbumEntity,
         shareCollectionUseCase: some ShareCollectionUseCaseProtocol,
         sectionViewModels: [GetLinkSectionViewModel],
         tracker: some AnalyticsTracking,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.album = album
        self.shareCollectionUseCase = shareCollectionUseCase
        self.sectionViewModels = sectionViewModels
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: GetLinkAction) {
        switch action {
        case .onViewReady:
            tracker.trackAnalyticsEvent(with: SingleAlbumLinkScreenEvent())
            updateViewConfiguration()
        case .onViewDidAppear where loadingTask == nil:
            loadingTask = Task { await startGetLinksCoordinatorStream() }
        case .switchToggled(indexPath: let indexPath, isOn: let isOn):
            handleSwitchToggled(forIndexPath: indexPath, isOn: isOn)
        case .shareLink(let sender):
            shareLink(sender: sender)
        case .copyLink:
            copyLinkToPasteBoard()
        case .copyKey:
            copyKeyToPasteBoard()
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
        let title = album.isLinkShared ? Strings.Localizable.General.MenuAction.ManageLink.title(1) :
        Strings.Localizable.General.MenuAction.ShareLink.title(1)
        invokeCommand?(.configureView(title: title,
                                      isMultilink: isMultiLink,
                                      shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)))
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
                await loadAlbumLink(continuation: continuation)
            case .authorized:
                invokeCommand?(.showHud(.status(Strings.Localizable.generatingLinks)))
                await loadAlbumLink(continuation: continuation)
            case .denied:
                invokeCommand?(.dismiss)
            }
        }
    }
    
    private func loadAlbumLink(continuation: Continuation) async {
        do { 
            if let albumLink = try await shareCollectionUseCase.shareCollectionLink(album),
               !Task.isCancelled {
                await updateLink(albumLink)
            }
        } catch {
            MEGALogError("Error sharing album link: \(error.localizedDescription)")
            invokeCommand?(.dismissHud)
        }
        continuation.finish()
    }
        
    private func determineIfAlbumsContainSensitiveNodes(continuation: Continuation) async {
        
        guard !album.isLinkShared else {
            continuation.yield(.authorized)
            return
        }
        
        invokeCommand?(.showHud(.status(Strings.Localizable.generatingLinks)))
        
        do {
            let result = try await shareCollectionUseCase.doesCollectionsContainSensitiveElement(for: [album])
            continuation.yield(result ? .notDetermined : .noSensitiveContent)
        } catch {
            MEGALogError("[\(type(of: self))]: determineIfAlbumsContainSensitiveNodes returned \(error.localizedDescription)")
            continuation.finish()
        }
    }
    
    @MainActor
    private func showContainsSensitiveContentAlert(continuation: Continuation) {
        
        invokeCommand?(.dismissHud)

        let alertModel = AlertModel(
            title: Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.title,
            message: Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.Message.single,
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
    private func updateLink(_ link: String) {
        shareLink = link
        
        guard let sectionIndex = sectionViewModels.firstIndex(where: { $0.sectionType == .link }),
              let rowIndex = sectionViewModels[safe: sectionIndex]?.cellViewModels.firstIndex(where: { $0.type == .link }) else {
            invokeCommand?(.dismissHud)
            return
        }
        
        sectionViewModels[sectionIndex].cellViewModels[rowIndex] = GetLinkStringCellViewModel(link: link)
        invokeCommand?(.enableLinkActions)
        invokeCommand?(.reloadRows([IndexPath(row: rowIndex, section: sectionIndex)]))
        invokeCommand?(.dismissHud)
    }
    
    private func handleSwitchToggled(forIndexPath indexPath: IndexPath, isOn: Bool) {
        if case .decryptKeySeparate = sectionViewModels[safe: indexPath.section]?.sectionType {
            guard let shareLink,
                  let linkSectionIndex = sectionViewModels.firstIndex(where: { $0.sectionType == .link }),
                  var switchCellViewmodel = sectionViewModels[indexPath.section].cellViewModels[safe: indexPath.row] as? GetLinkSwitchOptionCellViewModel else {
                return
            }
            switchCellViewmodel.isSwitchOn = isOn
            sectionViewModels[indexPath.section].cellViewModels[indexPath.row] = switchCellViewmodel
            if isOn {
                loadLinkAndKey(linkSectionIndex: linkSectionIndex, shareLink: shareLink)
            } else {
                loadFullLinkOnly(linkSectionIndex: linkSectionIndex, shareLink: shareLink)
            }
            invokeCommand?(.configureToolbar(isDecryptionKeySeperate: isOn))
        }
    }
    
    private func loadLinkAndKey(linkSectionIndex: Int, shareLink: String) {
        sectionViewModels[linkSectionIndex].cellViewModels = [GetLinkStringCellViewModel(link: linkWithoutKey(shareLink))]
        let keySectionIndex = linkSectionIndex + 1
        sectionViewModels.insert(contentsOf: [
            GetLinkSectionViewModel(sectionType: .key, cellViewModels: [
                GetLinkStringCellViewModel(key: key(shareLink))
            ])
        ], at: keySectionIndex)
        invokeCommand?(.insertSections([keySectionIndex]))
        invokeCommand?(.reloadSections([linkSectionIndex]))
    }
    
    private func loadFullLinkOnly(linkSectionIndex: Int, shareLink: String) {
        sectionViewModels[linkSectionIndex].cellViewModels = [GetLinkStringCellViewModel(link: shareLink)]
        invokeCommand?(.reloadSections([linkSectionIndex]))
        if let keySectionIndex = sectionViewModels.firstIndex(where: { $0.sectionType == .key }) {
            sectionViewModels.remove(at: keySectionIndex)
            invokeCommand?(.deleteSections([keySectionIndex]))
        }
    }
    
    private func shareLink(sender: UIBarButtonItem) {
        guard let shareLink else {
            return
        }
        if isDecryptingKeySeperately {
            invokeCommand?(.showShareActivity(sender: sender,
                                              link: linkWithoutKey(shareLink),
                                              key: key(shareLink)))
        } else {
            invokeCommand?(.showShareActivity(sender: sender,
                                              link: shareLink,
                                              key: nil))
        }
    }
    
    private func copyLinkToPasteBoard() {
        guard let shareLink else { return }
        if isDecryptingKeySeperately {
            invokeCommand?(.addToPasteBoard(linkWithoutKey(shareLink)))
        } else {
            invokeCommand?(.addToPasteBoard(shareLink))
        }
        
        invokeCommand?(.showHud(.custom(UIImage.copy,
                                        Strings.Localizable.SharedItems.GetLink.linkCopied(1))))
    }
    
    private func copyKeyToPasteBoard() {
        guard let shareLink else { return }
        invokeCommand?(.addToPasteBoard(key(shareLink)))
        invokeCommand?(.showHud(.custom(UIImage.copy,
                                        Strings.Localizable.keyCopiedToClipboard)))
    }
    
    private func linkWithoutKey(_ link: String) -> String {
        guard link.contains("collection") else {
            return ""
        }
        return link.components(separatedBy: "#").first ?? ""
    }
    
    private func key(_ link: String) -> String {
        guard link.contains("collection") else {
            return ""
        }
        return link.components(separatedBy: "#").last ?? ""
    }
}
