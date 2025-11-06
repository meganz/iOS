import Combine

public final class RecentlyWatchedVideosSharedUIState {
    @Published public var isRubbishBinBarButtonItemEnabled = false
    @Published public var shouldShowDeleteAlert = false
    
    public init() {}
}
