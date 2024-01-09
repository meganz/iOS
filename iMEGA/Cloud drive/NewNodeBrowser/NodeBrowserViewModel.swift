import Combine
import Foundation
import MEGADomain
import Search

class NodeBrowserViewModel: ObservableObject {
    
    let searchResultsViewModel: SearchResultsViewModel
    let mediaDiscoveryViewModel: MediaDiscoveryContentViewModel? // not available for recent buckets yet
    let config: NodeBrowserConfig
    var hasOnlyMediaNodesChecker: () async -> Bool
    
    @Published var shouldShowMediaDiscoveryAutomatically: Bool?
    @Published var viewMode: ViewModePreferenceEntity = .list
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        searchResultsViewModel: SearchResultsViewModel,
        mediaDiscoveryViewModel: MediaDiscoveryContentViewModel?,
        config: NodeBrowserConfig,
        // this is needed to check if given folder contains only visual media
        // so that we can automatically show media browser
        hasOnlyMediaNodesChecker: @escaping () async -> Bool
    ) {
        self.searchResultsViewModel = searchResultsViewModel
        self.mediaDiscoveryViewModel = mediaDiscoveryViewModel
        self.config = config
        self.hasOnlyMediaNodesChecker = hasOnlyMediaNodesChecker
        
        $viewMode
            .removeDuplicates()
            .sink { viewMode in
                if viewMode == .list {
                    searchResultsViewModel.layout = .list
                }
                if viewMode == .thumbnail {
                    searchResultsViewModel.layout = .thumbnail
                }
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
    
    // here we check the value of the automatic flag and also the actual variable that holds the state
    // which can be changed via the context menu
    var isMediaDiscoveryShown: Bool {
        shouldShowMediaDiscoveryAutomatically == true || viewMode == .mediaDiscovery
    }
}
