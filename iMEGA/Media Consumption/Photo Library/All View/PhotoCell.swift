import SwiftUI

@available(iOS 14.0, *)
struct PhotoCell: View {
    @ObservedObject var viewModel: PhotoCellViewModel
    
    var body: some View {
        if let path = viewModel.thumbnailURL?.path,
           let thumbnail = UIImage(contentsOfFile: path) {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
        } else {
            Image(viewModel.thumbnailPlaceholderFileType)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
        }
    }
}
