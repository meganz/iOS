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
    }
    
    var navigationBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    viewModel.onCancel()
                } label: {
                    Text(Strings.Localizable.cancel)
                        .font(.body)
                        .foregroundColor(textColor)
                }.padding(10)
                
                Text(Strings.Localizable.CameraUploads.Albums.selectAlbumCover)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                
                Button {
                    viewModel.onSave()
                } label: {
                    Text(Strings.Localizable.save)
                        .font(.body.bold())
                        .foregroundColor(textColor.opacity(viewModel.isSaveButtonDisabled ? 0.5 : 1))
                }.padding(10)
                .disabled(viewModel.isSaveButtonDisabled)
            }
            .padding(.bottom, 10)
            .padding(.top, 18)
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? MEGAAppColor.Gray._D1D1D1.color : MEGAAppColor.Gray._515151.color
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}
