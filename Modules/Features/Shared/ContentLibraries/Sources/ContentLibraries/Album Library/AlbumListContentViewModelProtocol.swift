import SwiftUI

@MainActor
public protocol AlbumListContentViewModelProtocol: ObservableObject {
    var albums: [AlbumCellViewModel] { get }
    var createButtonOpacity: Double { get }
    func columns(horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem]
    func onCreateAlbumTapped()
}
