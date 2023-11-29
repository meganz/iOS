import MEGASwiftUI
import SwiftUI

struct CameraUploadBannerStatusView: View {
        
    let previewEntity: any CameraUploadBannerStatusViewPresenterProtocol
    let onTapHandler: (() -> Void)
    
    var body: some View {
        Button(action: onTapHandler, label: content)
            .buttonStyle(.plain)
            .background(Color.primaryElevated)
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
            }
            .foregroundStyle(previewEntity.textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
            Divider()
                .background(ColorSchemeDesiredColor(lightMode: .gray3C3C43.opacity(0.65), darkMode: .gray545458.opacity(0.3)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(previewEntity.backgroundColor)
    }
}

struct CameraUploadBannerStatusView_Preview: PreviewProvider {
    
    private static let inProgressStatuses: [CameraUploadBannerStatusViewStates] = [
        .uploadInProgress(numberOfFilesPending: 1),
        .uploadInProgress(numberOfFilesPending: 32)
    ]
    
    private static let completedStatuses: [CameraUploadBannerStatusViewStates] = [
        .uploadCompleted
    ]
    
    private static let uploadPausedStatuses: [CameraUploadBannerStatusViewStates] = [
        .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 1)),
        .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 23))
    ]
    
    private static let uploadPartialCompletedStatuses: [CameraUploadBannerStatusViewStates] = [
        .uploadPartialCompleted(reason: .photoLibraryLimitedAccess),
        .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 1)),
        .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 23))
    ]
    
    private static func previewGroup(for name: String, statuses: [CameraUploadBannerStatusViewStates]) -> some View {
        let previews = statuses.map { $0.toPreviewEntity() }
        return VStack(spacing: 8) {
            ForEach(previews, id: \.self) { previewEntity in
                CameraUploadBannerStatusView(previewEntity: previewEntity) { }
            }
        }
        .previewDisplayName(name)
    }
    
    static var previews: some View {
        
        Group {
            previewGroup(for: "Uploads In-Progress", statuses: inProgressStatuses)
            previewGroup(for: "Uploads Completed", statuses: completedStatuses)
            previewGroup(for: "Uploads Paused", statuses: uploadPausedStatuses)
            previewGroup(for: "Uploads Partially Completed", statuses: uploadPartialCompletedStatuses)
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .background(ColorSchemeDesiredColor(lightMode: .red, darkMode: .green))
    }
}
