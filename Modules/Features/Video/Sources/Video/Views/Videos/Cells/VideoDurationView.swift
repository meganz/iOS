import SwiftUI

struct VideoDurationView: View {
    let duration: String
    let videoConfig: VideoConfig
    
    var body: some View {
        HStack {
            Text(duration)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(videoConfig.colorAssets.durationTextColor)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .background(videoConfig.colorAssets.videoThumbnailDurationTextBackgroundColor)
        .cornerRadius(4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VideoDurationView(duration: "00:45:00", videoConfig: .preview)
}
