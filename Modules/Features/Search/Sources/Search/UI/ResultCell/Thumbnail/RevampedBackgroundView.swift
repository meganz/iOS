import SwiftUI

/// View that displays either a full background image or a single color background and smaller icon image in the centre
/// depending on the mode property
/// It was refactored out of VerticalThumbnailView as it forms a separate unit and makes understanding VerticalThumbnailView easier
struct RevampedThumbnailBackgroundView: View {
    private static let thumbnailIconSize: CGFloat = 72
    let image: UIImage
    let isThumbnailLoaded: Bool
    let mode: VerticalBackgroundViewMode
    let backgroundColor: Color
    let isSensitive: Bool

    var body: some View {
        ZStack {
            backgroundColor
            switch mode {
            case .preview:
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .sensitive(isSensitive ? .blur : .none)
                    .animatedAppearance(isContentLoaded: isThumbnailLoaded)
                    .clipped()
            case .icon:
                thumbnailIconView
            }
        }
    }

    private var thumbnailIconView: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: Self.thumbnailIconSize, height: Self.thumbnailIconSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
