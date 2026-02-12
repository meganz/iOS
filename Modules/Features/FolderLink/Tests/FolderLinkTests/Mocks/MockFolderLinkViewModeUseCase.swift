import MEGADomain
import FolderLink
import Search

final class MockFolderLinkViewModeUseCase: FolderLinkViewModeUseCaseProtocol, @unchecked Sendable {
    let viewMode: SearchResultsViewMode
    let mediaDiscoveryModeEnabled: Bool
    private(set) var viewModeForOpeningFolderArgs: HandleEntity?
    init(viewMode: SearchResultsViewMode = .list, mediaDiscoveryModeEnabled: Bool = true) {
        self.viewMode = viewMode
        self.mediaDiscoveryModeEnabled = mediaDiscoveryModeEnabled
    }
    
    func viewModeForOpeningFolder(_ handle: HandleEntity) -> SearchResultsViewMode {
        viewModeForOpeningFolderArgs = handle
        return viewMode
    }
    
    func shouldEnableMediaDiscoveryMode(for handle: HandleEntity) -> Bool {
        mediaDiscoveryModeEnabled
    }
}
