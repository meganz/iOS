import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct AlbumContentPickerView: View {
    @StateObject var viewModel: AlbumContentPickerViewModel
    var invokeDismiss: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack {
            TokenColors.Background.surface1.swiftUI
            
            if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
                ZStack {
                    VStack(spacing: 0) {
                        navigationBar
                        
                        PhotoLibraryContentView(
                            viewModel: viewModel.photoLibraryContentViewModel,
                            router: PhotoLibraryContentViewRouter(),
                            onFilterUpdate: nil
                        )
                    }
                    
                    VStack(spacing: 0) {
                        Spacer()
                        footer
                    }
                }
            } else {
                VStack(spacing: 0) {
                    navigationBar
                    
                    PhotoLibraryContentView(
                        viewModel: viewModel.photoLibraryContentViewModel,
                        router: PhotoLibraryContentViewRouter(),
                        onFilterUpdate: nil
                    )
                    
                    Spacer()
                    footer
                }
            }
        }
        .alert(isPresented: $viewModel.showSelectionLimitReachedAlert) {
            Alert(title: Text(Strings.Localizable.CameraUploads.Albums.AddItems.Alert.LimitReached.title),
                  message: Text(Strings.Localizable.CameraUploads.Albums.AddItems.Alert.LimitReached.message(viewModel.selectLimit)),
                  dismissButton: .default(Text(Strings.Localizable.ok)))
        }
        .onChange(of: viewModel.shouldDismiss) {
            if $0 {
                dismiss()
            }
        }
        .edgesIgnoringSafeArea(.vertical)
    }
    
    var navigationBar: some View {
        VStack(spacing: 0) {
            Text(viewModel.navigationTitle)
                .lineLimit(1)
                .font(.footnote)
                .foregroundColor(.primary)
                .padding(.bottom, 14)
                .padding(.top, 18)
                .padding(.horizontal, 30)
            
            HStack {
                if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
                    cancelButton
                        .buttonStyle(.glass)
                } else {
                    cancelButton
                }
                
                Text(viewModel.photoSourceLocationNavigationTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                
                if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
                    doneButton
                        .buttonStyle(.glass)
                } else {
                    doneButton
                }
            }.padding(.bottom, 10)
        }
    }
    
    var cancelButton: some View {
        Button {
            viewModel.onCancel()
        } label: {
            if DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosMediaRevamp) {
                MEGAAssets.Image.closeBannerButton
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            } else {
                Text(Strings.Localizable.cancel)
                    .font(.body)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            }
        }.padding(10)
    }
    
    var doneButton: some View {
        Button {
            viewModel.onDone()
        } label: {
            Text(Strings.Localizable.done)
                .font(.body.bold())
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI.opacity(viewModel.isDoneButtonDisabled ? 0.5 : 1))
        }.padding(10)
        .disabled(viewModel.isDoneButtonDisabled)
    }
    
    @ViewBuilder
    var footer: some View {
        if !viewModel.shouldRemoveFilter {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    
                    if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
                        filterButton
                            .buttonStyle(.glass)
                    } else {
                        filterButton
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    var filterButton: some View {
        Button {
            viewModel.onFilter()
        } label: {
            Text(Strings.Localizable.filter)
                .font(.body)
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
        }.padding(20)
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}
