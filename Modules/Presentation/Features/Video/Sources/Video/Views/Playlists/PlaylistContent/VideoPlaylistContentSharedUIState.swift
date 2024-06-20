import Combine
import MEGADomain

public final class VideoPlaylistContentSharedUIState {
    @Published public var videosCount = 0
    @Published public var selectedDisplayActionEntity: DisplayActionEntity?
    @Published public var selectedSortOrderEntity: SortOrderEntity?
    @Published public var shouldShowSnackBar = false
    @Published public var snackBarText = ""
    @Published public var isAllSelected = false
    
    public init() {}
}
