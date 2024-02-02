import MEGAAssets
import SwiftUI

struct VideoToolbar: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    let videoConfig: VideoConfig
    let isDisabled: Bool
    
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
        .disabled(isDisabled)
    }
    
    @ViewBuilder
    private func image(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .renderingMode(isDisabled ? .template : .original)
            .resizable()
            .frame(width: 28, height: 28)
    }
}

struct VideoToolbar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoToolbar(videoConfig: .preview, isDisabled: false)
            VideoToolbar(videoConfig: .preview, isDisabled: true)
        }
    }
}
