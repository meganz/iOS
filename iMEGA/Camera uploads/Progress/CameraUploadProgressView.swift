import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct CameraUploadProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CameraUploadProgressViewModel
    
    var body: some View {
        NavigationStack {
            contentView
                .alertPhotosPermission(isPresented: $viewModel.showPhotoPermissionAlert)
                .edgesIgnoringSafeArea(.all)
                .pageBackground()
                .navigationTitle(Strings.Localizable.CameraUploads.Progress.Navigation.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: { XmarkCloseButton() }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: viewModel.showCameraUploadSettings) {
                            MEGAAssets.Image.gearSixMediumThin
                                .renderingMode(.template)
                                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        }
                    }
                }
                .hideNavigationToolbarBackground()
        }
        .pageBackground()
        .task {
            await viewModel.monitorStates()
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            uploadingView(isLoading: viewModel.viewState == .loading)
            
            if viewModel.viewState == .completed {
                completedView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func uploadingView(isLoading: Bool) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            bannerView
            
            uploadStatusView(isLoading: isLoading)
            
            CameraUploadProgressTableView(viewModel: viewModel.cameraUploadProgressTableViewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var completedView: some View {
        ZStack(alignment: .top) {
            VStack {
                VStack(alignment: .center, spacing: TokenSpacing._7) {
                    MEGAAssets.Image.glassCheckCircle
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                    
                    VStack(alignment: .center, spacing: TokenSpacing._5) {
                        Text(Strings.Localizable.CameraUploads.Progress.UploadsComplete.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        
                        Text(Strings.Localizable.CameraUploads.Progress.UploadsComplete.subtitle)
                            .font(.callout)
                            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: 370)
                .padding(TokenSpacing._5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            
            bannerView
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pageBackground()
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
    
    private func uploadStatusView(isLoading: Bool) -> some View {
        Text(viewModel.uploadStatus)
            .font(.subheadline)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .padding(TokenSpacing._5)
            .overlay(alignment: .leading) {
                if isLoading {
                    RoundedRectangle(cornerRadius: TokenRadius.medium, style: .continuous)
                        .frame(width: 120, height: 20)
                        .shimmering()
                        .padding(TokenSpacing._5)
                }
            }
    }
}
