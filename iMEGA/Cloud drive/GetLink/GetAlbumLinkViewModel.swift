import Foundation
import MEGAPresentation
import MEGADomain

final class GetAlbumLinkViewModel: GetLinkViewModelType {
    var invokeCommand: ((GetLinkViewModelCommand) -> Void)?
    
    private let album: AlbumEntity
    private let shareAlbumUseCase: ShareAlbumUseCaseProtocol
    private var sectionViewModels = [GetLinkSectionViewModel]()
    private var shareLink: String?
    
    let isMultiLink: Bool = false
    
    var numberOfSections: Int {
        sectionViewModels.count
    }
    
    init(album: AlbumEntity, shareAlbumUseCase: ShareAlbumUseCaseProtocol,
         sectionViewModels: [GetLinkSectionViewModel]) {
        self.album = album
        self.shareAlbumUseCase = shareAlbumUseCase
        self.sectionViewModels = sectionViewModels
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: GetLinkAction) {
        switch action {
        case .onViewReady:
            updateViewConfiguration()
            loadAlbumLinks()
        case .switchToggled(indexPath: let indexPath, isOn: let isOn):
            handleSwitchToggled(forIndexPath: indexPath, isOn: isOn)
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
    
    //MARK: - Private
    private func updateViewConfiguration() {
        let title = album.sharedLinkStatus == .exported(true) ? Strings.Localizable.General.MenuAction.ManageLink.title(1) :
        Strings.Localizable.General.MenuAction.ShareLink.title(1)
        invokeCommand?(.configureView(title: title, isMultilink: isMultiLink))
    }
    
    private func loadAlbumLinks() {
        Task { [weak self] in
            guard let self else { return }
            do {
                if let albumLink = try await shareAlbumUseCase.shareAlbumLink(album) {
                    shareLink = albumLink
                    await updateLink(albumLink)
                }
            } catch {
                MEGALogError("Error sharing album link: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func updateLink(_ link: String) {
        guard let sectionIndex = sectionViewModels.firstIndex(where: { $0.sectionType == .link }),
              let rowIndex = sectionViewModels[safe: sectionIndex]?.cellViewModels.firstIndex(where: { $0.type == .link }) else {
            return
        }
        sectionViewModels[sectionIndex].cellViewModels[rowIndex] = GetLinkStringCellViewModel(link: link)
        invokeCommand?(.enableLinkActions)
        invokeCommand?(.reloadRows([IndexPath(row: rowIndex, section: sectionIndex)]))
    }
    
    private func handleSwitchToggled(forIndexPath indexPath: IndexPath, isOn: Bool) {
        if case .decryptKeySeparate = sectionViewModels[safe: indexPath.section]?.sectionType {
            guard let shareLink,
                  let linkSectionIndex = sectionViewModels.firstIndex(where: { $0.sectionType == .link }),
                  let cellViewmodel = sectionViewModels[indexPath.section].cellViewModels[safe: indexPath.row] as? GetLinkSwitchOptionCellViewModel else {
                return
            }
            cellViewmodel.dispatch(.onSwitchToggled(isOn: isOn))
            if isOn {
                loadLinkAndKey(linkSectionIndex: linkSectionIndex, shareLink: shareLink)
            } else {
                loadFullLinkOnly(linkSectionIndex: linkSectionIndex, shareLink: shareLink)
            }
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
