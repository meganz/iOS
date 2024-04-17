import MEGAAssets
import SwiftUI

struct VideoToolbar: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let videoConfig: VideoConfig
    @StateObject private var viewModel: VideoToolbarViewModel
    
    init(
        videoConfig: VideoConfig,
        viewModel: @autoclosure @escaping () -> VideoToolbarViewModel
    ) {
        self.videoConfig = videoConfig
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    var body: some View {
        HStack {
            Group {
                Button {
                    // Action for Button 1
                } label: {
                    image(uiImage: videoConfig.toolbarAssets.offlineImage)
                }
                
                Button {
                    // Action for Button 2
                } label: {
                    image(uiImage: videoConfig.toolbarAssets.linkImage)
                }
                
                Button {
                    // Action for Button 3
                } label: {
                    image(uiImage: videoConfig.toolbarAssets.saveToPhotosImage)
                }
                
                Button {
                    // Action for Button 4
                } label: {
                    image(uiImage: videoConfig.toolbarAssets.hudMinusImage)
                }
                
                Button {
                    // Action for Button 5
                } label: {
                    image(uiImage: videoConfig.toolbarAssets.moreListImage)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(videoConfig.colorAssets.toolbarBackgroundColor)
        .disabled(viewModel.isDisabled)
    }
    
    @ViewBuilder
    private func image(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(iconForegroundColor)
            .frame(width: 28, height: 28)
    }
    
    private var iconForegroundColor: Color {
        viewModel.isDisabled ? videoConfig.colorAssets.disabledColor : videoConfig.colorAssets.primaryIconColor
    }
}

struct VideoToolbar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoToolbar(videoConfig: .preview, viewModel: VideoToolbarViewModel(isDisabled: true))
            VideoToolbar(videoConfig: .preview, viewModel: VideoToolbarViewModel(isDisabled: false))
        }
    }
}
