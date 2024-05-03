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
            } description: { _ in
                Text(title)
                    .font(.body)
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
