import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct CameraUploadProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CameraUploadProgressViewModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .zero) {
                bannerView
                
                Text(viewModel.uploadStatus)
                    .font(.subheadline)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .padding(TokenSpacing._5)
                
                CameraUploadProgressTableView(viewModel: viewModel.cameraUploadProgressTableViewModel)
            }
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .pageBackground()
            .navigationTitle(Strings.Localizable.CameraUploads.Progress.Navigation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { XmarkCloseButton() }
                }
            }
            .hideNavigationToolbarBackground()
        }
        .pageBackground()
        .task {
            await viewModel.monitorStates()
        }
    }
    
    @ViewBuilder
    private var bannerView: some View {
        if let bannerViewModel = viewModel.bannerViewModel {
            MEGABanner(
                title: bannerViewModel.title,
                subtitle: bannerViewModel.subtitle,
                buttonText: bannerViewModel.buttonViewModel?.text,
                state: bannerViewModel.state,
                buttonAction: bannerViewModel.buttonViewModel?.action)
        }
    }
}
