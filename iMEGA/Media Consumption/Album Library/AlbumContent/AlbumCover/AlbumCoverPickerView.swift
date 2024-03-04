import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct AlbumCoverPickerView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var viewModel: AlbumCoverPickerViewModel
    var invokeDismiss: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            
            ScrollView {
                LazyVGrid(columns: viewModel.columns(horizontalSizeClass: horizontalSizeClass), spacing: 4) {
                    ForEach(viewModel.photos, id: \.self) { albumPhoto in
                        viewModel.router.albumCoverPickerPhotoCell(albumPhoto: albumPhoto, photoSelection: viewModel.photoSelection)
                            .clipped()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadAlbumContents()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
        .onChange(of: viewModel.isDismiss, perform: { newValue in
            if newValue {
                dismiss()
            }
        })
        .edgesIgnoringSafeArea(.vertical)
        .background(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : nil)
    }
    
    @ViewBuilder
    var navigationBar: some View {
        ZStack(alignment: .top) {
            Group {
                isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.clear
            }
            .ignoresSafeArea()
            
            NavigationBarView(
                leading: {
                    Button {
                        viewModel.onCancel()
                    } label: {
                        Text(Strings.Localizable.cancel)
                            .font(.body)
                            .foregroundColor(textColor)
                    }
                },
                trailing: {
                    Button {
                        viewModel.onSave()
                    } label: {
                        Text(Strings.Localizable.save)
                            .font(.body.bold())
                            .foregroundColor(textColor.opacity(viewModel.isSaveButtonDisabled ? 0.5 : 1))
                    }
                    .disabled(viewModel.isSaveButtonDisabled)
                },
                center: {
                    NavigationTitleView(title: Strings.Localizable.CameraUploads.Albums.selectAlbumCover)
                },
                leadingWidth: 75,
                trailingWidth: 75,
                backgroundColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.clear
            )
            .padding(.top, 16)
        }
        .frame(height: 60)
    }
    
    private var textColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Text.primary.swiftUI
        } else {
            colorScheme == .dark ? UIColor.grayD1D1D1.swiftUI : UIColor.gray515151.swiftUI
        }
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}
