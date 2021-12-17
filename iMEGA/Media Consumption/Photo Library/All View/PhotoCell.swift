import SwiftUI

@available(iOS 14.0, *)
struct PhotoCell: View {
    var inEditingMode: Bool = false
    
    @ObservedObject var viewModel: PhotoCellViewModel
    @State private var selected: Bool = false
    
    private var tap: some Gesture { TapGesture().onEnded { _ in selected.toggle() }}
    
    var body: some View {
        if let path = viewModel.thumbnailURL?.path,
           let thumbnail = UIImage(contentsOfFile: path) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                
                if inEditingMode {
                    CheckMarkView(markedSelected: $selected)
                        .offset(x: -5, y: 5)
                }
            }
            .gesture(inEditingMode ? tap : nil)
        } else {
            Image(viewModel.thumbnailPlaceholderFileType)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
        }
    }
}
