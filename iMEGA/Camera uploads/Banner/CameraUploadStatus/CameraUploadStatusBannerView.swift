import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct CameraUploadBannerStatusView: View {
        
    let previewEntity: any CameraUploadBannerStatusViewPresenterProtocol
    let onTapHandler: (() -> Void)
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTapHandler, label: content)
            .buttonStyle(.plain)
            .background(backgroundColor)
    }

    private var backgroundColor: Color {
        TokenColors.Background.page.swiftUI
    }

    @ViewBuilder
    private func content() -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(previewEntity.title)
                    .font(.system(.footnote).bold())
                Text(previewEntity.subheading)
                    .font(.caption2)
                    .multilineTextAlignment(.leading)
                    .monospacedDigit()
            }
            .foregroundStyle(previewEntity.textColor(for: colorScheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            Divider()
                .background(previewEntity.bottomBorder(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(previewEntity.backgroundColor(for: colorScheme))
    }
}

#Preview("Uploads In-Progress") {
    VStack(spacing: 8) {
        CameraUploadBannerStatusView(previewEntity: CameraUploadBannerStatusViewStates.uploadInProgress(numberOfFilesPending: 1).toPreviewEntity()) {}
        CameraUploadBannerStatusView(previewEntity: CameraUploadBannerStatusViewStates.uploadInProgress(numberOfFilesPending: 32).toPreviewEntity()) {}
    }
    .frame(maxHeight: .infinity, alignment: .center)
    .background(.background)
}

#Preview("Uploads Completed") {
    VStack(spacing: 8) {
        CameraUploadBannerStatusView(previewEntity: CameraUploadBannerStatusViewStates.uploadCompleted.toPreviewEntity()) {}
    }
    .frame(maxHeight: .infinity, alignment: .center)
    .background(.background)
}

#Preview("Uploads Paused") {
    VStack(spacing: 8) {
        CameraUploadBannerStatusView(previewEntity: CameraUploadBannerStatusUploadPausedReason.noWifiConnection(numberOfFilesPending: 1)) {}
        CameraUploadBannerStatusView(previewEntity: CameraUploadBannerStatusUploadPausedReason.noWifiConnection(numberOfFilesPending: 23)) {}
    }
    .frame(maxHeight: .infinity, alignment: .center)
    .background(.background)
}

#Preview("Uploads Partially Completed") {
    VStack(spacing: 8) {
        CameraUploadBannerStatusView(previewEntity: CameraUploadBannerStatusViewStates.uploadPartialCompleted(reason: .photoLibraryLimitedAccess).toPreviewEntity()) {}
        CameraUploadBannerStatusView(previewEntity: CameraUploadBannerStatusPartiallyCompletedReason.videoUploadIsNotEnabled(pendingVideoUploadCount: 1)) {}
        CameraUploadBannerStatusView(previewEntity: CameraUploadBannerStatusPartiallyCompletedReason.videoUploadIsNotEnabled(pendingVideoUploadCount: 23)) {}
    }
    .frame(maxHeight: .infinity, alignment: .center)
    .background(.background)
}
