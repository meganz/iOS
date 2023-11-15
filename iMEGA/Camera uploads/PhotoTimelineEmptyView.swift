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
            
            ContentUnavailableView_iOS16 {
                Image(centerImageResource)
            } description: {
                Text(title)
                    .font(.body)
            }
            .frame(maxHeight: .infinity)
        }
    }
}

struct PhotoTimelineEmptyView_Preview: PreviewProvider {
    static var previews: some View {
        PhotoTimelineEmptyView(centerImageResource: .cameraEmptyState,
                               title: "No media found",
                               enableCameraUploadsAction: nil)
        .previewDisplayName("No enable camera uploads banner")
        
        PhotoTimelineEmptyView(centerImageResource: .cameraEmptyState,
                               title: "No media found") { }
        .previewDisplayName("With camera uploads banner")
    }
}
