import MEGAAssets
import MEGADesignToken
import SwiftUI

struct VideoPlaylistSecondaryInformationView: View {
    let videosCount: String
    let totalDuration: String
    let isPublicLink: Bool
    let layoutIgnoringOrientation: Bool
    
    @State private var isPortrait = true
    
    var body: some View {
        content
            .onOrientationChanged { newOrientation in
                isPortrait = newOrientation.isPortrait
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if layoutIgnoringOrientation || isPortrait {
            horizontalLayoutContent
        } else {
            verticalLayoutContent
        }
    }
    
    private var horizontalLayoutContent: some View {
        HStack(spacing: TokenSpacing._3) {
            secondaryText(text: videosCount)
            
            circleSeparatorImage
            
            secondaryText(text: totalDuration)
            
            circleSeparatorImage
                .opacity(isPublicLink ? 1 : 0)
            
            MEGAAssetsImageProvider.image(named: .linked)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .opacity(isPublicLink ? 1 : 0)
        }
    }
    
    private var verticalLayoutContent: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            secondaryText(text: videosCount)
            
            secondaryText(text: totalDuration)
            
            MEGAAssetsImageProvider.image(named: .linked)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .opacity(isPublicLink ? 1 : 0)
        }
    }
    
    private func secondaryText(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }
    
    private var circleSeparatorImage: some View {
        Image(systemName: "circle.fill")
            .renderingMode(.template)
            .resizable()
            .frame(width: 4, height: 4)
            .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
    }
}

#Preview {
    VideoPlaylistSecondaryInformationView(
        videosCount: "24 videos",
        totalDuration: "3:05:20",
        isPublicLink: true,
        layoutIgnoringOrientation: true
    )
}

#Preview {
    VideoPlaylistSecondaryInformationView(
        videosCount: "24 videos",
        totalDuration: "3:05:20",
        isPublicLink: false,
        layoutIgnoringOrientation: true
    )
    .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview(traits: .landscapeLeft) {
    VideoPlaylistSecondaryInformationView(
        videosCount: "24 videos",
        totalDuration: "3:05:20",
        isPublicLink: false,
        layoutIgnoringOrientation: false
    )
    .preferredColorScheme(.dark)
}
