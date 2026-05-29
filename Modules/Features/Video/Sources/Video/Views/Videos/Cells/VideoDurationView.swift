import SwiftUI

struct VideoDurationView: View {
    let duration: String
    let videoConfig: VideoConfig

    var body: some View {
        HStack {
            Text(duration)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 2)
        .background(.black.opacity(0.7))
        .cornerRadius(1)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

#Preview {
    VideoDurationView(duration: "00:45:00", videoConfig: .preview)
}
