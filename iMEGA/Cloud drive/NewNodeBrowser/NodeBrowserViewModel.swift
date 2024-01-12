import Combine
import Foundation
import MEGADomain
import MEGAL10n
import Search

class NodeBrowserViewModel: ObservableObject {
    
    let searchResultsViewModel: SearchResultsViewModel
    let mediaDiscoveryViewModel: MediaDiscoveryContentViewModel? // not available for recent buckets yet
    let warningViewModel: WarningViewModel?
    let config: NodeBrowserConfig
    var hasOnlyMediaNodesChecker: () async -> Bool

    @Published var shouldShowMediaDiscoveryAutomatically: Bool?
    @Published var viewMode: ViewModePreferenceEntity = .list

    private var subscriptions = Set<AnyCancellable>()

    let avatarViewModel: MyAvatarViewModel

    private let nodeSource: NodeSource
    private let onOpenUserProfile: () -> Void
    private let onUpdateSearchBarVisibility: (Bool) -> Void
    private let onBack: () -> Void

    init(
        searchResultsViewModel: SearchResultsViewModel,
        mediaDiscoveryViewModel: MediaDiscoveryContentViewModel?,
        warningViewModel: WarningViewModel?,
        config: NodeBrowserConfig,
        nodeSource: NodeSource,
        avatarViewModel: MyAvatarViewModel,
        // this is needed to check if given folder contains only visual media
        // so that we can automatically show media browser
        hasOnlyMediaNodesChecker: @escaping () async -> Bool,
        onOpenUserProfile: @escaping () -> Void,
        onUpdateSearchBarVisibility: @escaping (Bool) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.searchResultsViewModel = searchResultsViewModel
        self.mediaDiscoveryViewModel = mediaDiscoveryViewModel
        self.warningViewModel = warningViewModel
        self.config = config
        self.nodeSource = nodeSource
        self.avatarViewModel = avatarViewModel
        self.onOpenUserProfile = onOpenUserProfile
        self.hasOnlyMediaNodesChecker = hasOnlyMediaNodesChecker
        self.onUpdateSearchBarVisibility = onUpdateSearchBarVisibility
        self.onBack = onBack

        $viewMode
            .removeDuplicates()
            .sink { viewMode in
                if viewMode == .list {
                    searchResultsViewModel.layout = .list
                }
                if viewMode == .thumbnail {
                    searchResultsViewModel.layout = .thumbnail
                }

                onUpdateSearchBarVisibility(!self.isMediaDiscoveryShown(for: viewMode))
            }.store(in: &subscriptions)
    }
    
    @MainActor
    func viewTask() async {
        await determineIfHasVisualMediaIfNeeded()
        determineIfShowingAutomaticallyMediaDiscovery()
    }
    
    private func determineIfShowingAutomaticallyMediaDiscovery() {
        mediaDiscoveryViewModel?
            .showAutoMediaDiscoveryBanner = shouldShowMediaDiscoveryAutomatically == true
    }
    
    @MainActor
    private func determineIfHasVisualMediaIfNeeded() async {
        guard config.mediaDiscoveryAutomaticDetectionEnabled() else {
            return
        }
        
        if shouldShowMediaDiscoveryAutomatically != nil {
            return
        }
        // first time we load view, we need to get
        // all nodes list to see if there are any media
        // in case we need to automatically show media discovery view
        shouldShowMediaDiscoveryAutomatically = await hasOnlyMediaNodesChecker()
    }

    private func isMediaDiscoveryShown(for viewMode: ViewModePreferenceEntity) -> Bool {
        shouldShowMediaDiscoveryAutomatically == true || viewMode == .mediaDiscovery
    }

    // here we check the value of the automatic flag and also the actual variable that holds the state
    // which can be changed via the context menu
    var isMediaDiscoveryShown: Bool {
        isMediaDiscoveryShown(for: viewMode)
    }

    var title: String? {
        guard let parentNode else { return nil }
        return parentNode.nodeType == .root ? Strings.Localizable.cloudDrive : parentNode.name
    }

    var isBackButtonShown: Bool {
       guard let parentNode else { return false }
       return parentNode.nodeType != .root
    }

    private var parentNode: NodeEntity? {
        switch nodeSource {
        case .node(let parentNodeProvider):
            guard let parentNodeProvider = parentNodeProvider() else { return nil }
            return parentNodeProvider
        default:
            return nil
        }
    }

    func openUserProfile() {
        onOpenUserProfile()
    }

    func back() {
        onBack()
    }
}
