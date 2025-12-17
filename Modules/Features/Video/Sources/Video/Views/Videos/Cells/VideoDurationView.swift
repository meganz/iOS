import SwiftUI

struct VideoDurationView: View {
    let duration: String
    let videoConfig: VideoConfig
    let isMediaRevampEnabled: Bool

    init(
        duration: String,
        videoConfig: VideoConfig,
        isMediaRevampEnabled: Bool = false
    ) {
        self.duration = duration
        self.videoConfig = videoConfig
        self.isMediaRevampEnabled = isMediaRevampEnabled
    }

    var body: some View {
        HStack {
            Text(duration)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(textColor)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, horizontalPadding)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .frame(maxWidth: .infinity, alignment: alignment)
    }

    private var textColor: Color {
        isMediaRevampEnabled ? .white : videoConfig.colorAssets.durationTextColor
    }

    private var backgroundColor: Color {
        isMediaRevampEnabled ? .black.opacity(0.7) : videoConfig.colorAssets.videoThumbnailDurationTextBackgroundColor
    }

    private var alignment: Alignment {
        isMediaRevampEnabled ? .trailing : .leading
    }
    
    private var cornerRadius: CGFloat {
        isMediaRevampEnabled ? 1 : 4
    }
    
    private var horizontalPadding: CGFloat {
        isMediaRevampEnabled ? 2 : 4
    }
}

#Preview {
    VideoDurationView(duration: "00:45:00", videoConfig: .preview)
}
