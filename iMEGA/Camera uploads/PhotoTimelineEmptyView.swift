import ContentLibraries
import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct PhotoTimelineEmptyView: View {
    let centerImage: Image
    let title: String
    let enableCameraUploadsAction: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .top) {
            if let enableCameraUploadsAction {
                EnableCameraUploadsBannerButtonView(enableCameraUploadsAction)
            }
            
            ContentUnavailableView {
                centerImage
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            } description: {
                Text(title)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
            }
            .frame(maxHeight: .infinity)
        }
        .background()
    }
}

#Preview("No enable camera uploads banner") {
    PhotoTimelineEmptyView(centerImage: MEGAAssets.Image.cameraEmptyState,
                           title: "No media found",
                           enableCameraUploadsAction: nil)
}

#Preview("With camera uploads banner") {
    PhotoTimelineEmptyView(centerImage: MEGAAssets.Image.cameraEmptyState,
                           title: "No media found") { }
}

#Preview("All photos empty") {
    PhotoTimelineEmptyView(centerImage: MEGAAssets.Image.allPhotosEmptyState,
                           title: "No media found",
                           enableCameraUploadsAction: nil)
}

#Preview("All photos empty") {
    PhotoTimelineEmptyView(centerImage: MEGAAssets.Image.videoEmptyState,
                           title: "No media found",
                           enableCameraUploadsAction: nil)
}
