import SwiftUI
import Combine
import MEGADomain

final class PhotoAlbumContainerViewModel: ObservableObject {
    @Published var editMode: EditMode = .inactive
    @Published var shouldShowSelectBarButton = false
    @Published var numOfSelectedAlbums = 0
    @Published var showDeleteAlbumAlert = false
    
    var disableSelectBarButton = false
}
