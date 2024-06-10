import SwiftUI

public enum VerticalBackgroundViewMode: Sendable {
    case preview
    case icon
}

/// View that displays either a full background image or a single color background and smaller icon image in the centre
/// depending on the mode property
/// It was refactored out of VerticalThumbnailView as it forms a separate unit and make understanding VerticalThumbnailView easier
struct BackgroundView<Header: View, Footer: View>: View {
    var image: UIImage
    var isThumbnailLoaded: Bool
    let mode: VerticalBackgroundViewMode
    let backgroundColor: Color
    let header: Header
    let footer: Footer
    let isSensitive: Bool
    
    var body: some View {
        ZStack {
            background
            VStack(spacing: .zero) {
                header
                
                switch mode {
                case .preview:
                    Spacer()
                case .icon:
                    thumbnailIconView
                }
            }
            .overlay(footer, alignment: .bottomLeading)
        }
    }
    
    @ViewBuilder
    private var background: some View {
        
        switch mode {
        case .preview:
            Image(uiImage: image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .sensitive(isSensitive ? .blur : .none)
                .frame(height: 174)
                .animatedAppearance(isContentLoaded: isThumbnailLoaded)
                .clipped()
        case .icon:
            backgroundColor.opacity(0.9)
        }
    }
    
    private var thumbnailIconView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                Spacer()
            }
            Spacer()
        }
    }
}
