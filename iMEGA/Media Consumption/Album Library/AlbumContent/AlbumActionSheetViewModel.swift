import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import SwiftUI

@MainActor
final class AlbumActionSheetViewModel: ObservableObject {
    struct SheetAction {
        let icon: Image
        let iconColor: Color
        let title: String
        let titleColor: Color
        let action: () -> Void
        
        init(
            icon: Image,
            iconColor: Color = TokenColors.Icon.primary.swiftUI,
            title: String,
            titleColor: Color = TokenColors.Text.primary.swiftUI,
            action: @escaping () -> Void
        ) {
            self.icon = icon
            self.iconColor = iconColor
            self.title = title
            self.titleColor = titleColor
            self.action = action
        }
    }
    
    @Published var thumbnailContainer: any ImageContaining
    let title: String
    let sheetActions: [SheetAction]
    private let albumCover: NodeEntity?
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    
    init(
        albumCover: NodeEntity?,
        title: String,
        sheetActions: [SheetAction],
        thumbnailLoader: any ThumbnailLoaderProtocol
    ) {
        self.albumCover = albumCover
        self.title = title
        self.sheetActions = sheetActions
        self.thumbnailLoader = thumbnailLoader
        
        if let albumCover {
            thumbnailContainer = thumbnailLoader.initialImage(
                for: albumCover,
                type: .thumbnail,
                placeholder: { MEGAAssets.Image.image04Solid })
        } else {
            thumbnailContainer = ImageContainer(
                image: MEGAAssets.Image.image04Solid,
                type: .placeholder)
        }
    }
    
    func loadAlbumCoverThumbnail() async {
        guard let albumCover,
              thumbnailContainer.type == .placeholder,
              let imageContainer = try? await thumbnailLoader.loadImage(for: albumCover, type: .thumbnail) else {
            return
        }
        
        thumbnailContainer = imageContainer
    }
}

extension AlbumActionSheetViewModel.SheetAction: Identifiable {
    var id: String { title }
}
