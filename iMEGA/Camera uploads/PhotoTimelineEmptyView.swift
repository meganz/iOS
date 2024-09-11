import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct PhotoTimelineEmptyView: View {
    let centerImageResource: ImageResource
    let title: String
    let enableCameraUploadsAction: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .top) {
            if let enableCameraUploadsAction {
                EnableCameraUploadsBannerButtonView(enableCameraUploadsAction)
            }
            
            ContentUnavailableView {
                Image(centerImageResource)
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            } description: {
                Text(title)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
            }
            .frame(maxHeight: .infinity)
        }
    }
}

#Preview("No enable camera uploads banner") {
    PhotoTimelineEmptyView(centerImageResource: .cameraEmptyState,
                           title: "No media found",
                           enableCameraUploadsAction: nil)
}

#Preview("With camera uploads banner") {
    PhotoTimelineEmptyView(centerImageResource: .cameraEmptyState,
                           title: "No media found") { }
}

#Preview("All photos empty") {
    PhotoTimelineEmptyView(centerImageResource: .allPhotosEmptyState,
                           title: "No media found",
                           enableCameraUploadsAction: nil)
}

#Preview("All photos empty") {
    PhotoTimelineEmptyView(centerImageResource: .videoEmptyState,
                           title: "No media found",
                           enableCameraUploadsAction: nil)
}
