import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
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
        .background(TokenColors.Background.page.swiftUI)
    }
    
    @ViewBuilder
    var navigationBar: some View {
        ZStack(alignment: .top) {
            Group {
                TokenColors.Background.surface1.swiftUI
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
                backgroundColor: TokenColors.Background.surface1.swiftUI
            )
            .padding(.top, 16)
        }
        .frame(height: 60)
    }
    
    private var textColor: Color {
        TokenColors.Text.primary.swiftUI
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}
