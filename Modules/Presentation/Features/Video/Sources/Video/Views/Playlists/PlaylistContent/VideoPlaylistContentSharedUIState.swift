import Combine
import MEGADomain

public final class VideoPlaylistContentSharedUIState {
    @Published public var videosCount = 0
    @Published public var selectedDisplayActionEntity: DisplayActionEntity?
    
    public init() {}
}
