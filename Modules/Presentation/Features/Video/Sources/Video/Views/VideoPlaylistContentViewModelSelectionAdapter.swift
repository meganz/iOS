import MEGADomain

/// An adapter component to helps decouple `VideoSelection` from the `VideoPlaylistContentViewModel`. This pattern is needed, so that we won't have `ObservableObject` object inside of an `ObservableObject` component, avoiding unwanted behavior in SwiftUI.
public final class VideoPlaylistContentViewModelSelectionAdapter: VideoPlaylistContentViewModelSelectionDelegate {
    
    private let selection: VideoSelection
    
    public init(selection: VideoSelection) {
        self.selection = selection
    }
    
    public func didChangeAllSelectedValue(allSelected: Bool, videos: [NodeEntity]) {
        toggleSelectAllVideos(videos: videos)
    }
    
    private func toggleSelectAllVideos(videos: [NodeEntity]) {
        let allSelectedCurrently = selection.videos.count == videos.count
        selection.allSelected = !allSelectedCurrently
        
        if selection.allSelected {
            selection.setSelectedVideos(videos)
        }
    }
}
