import Combine

enum PhotoLibraryTab: CaseIterable {
    case timeline
    case album
    
    var index: Int {
        switch self {
        case.timeline: return 0
        case.album: return 1
        }
    }
}

final class PagerTabViewModel: ObservableObject {
    @Published var tabOffset: CGFloat = 0
    @Published var selectedTab = PhotoLibraryTab.timeline
    @Published var isEditing = false
    
    var timeLineTitle = Strings.Localizable.CameraUploads.Timeline.title
    var albumsTitle = Strings.Localizable.CameraUploads.Albums.title
}
