import SwiftUI

@available(iOS 14.0, *)
struct PhotoCell: View {
    @State private var selected: Bool = false
    @StateObject var viewModel: PhotoCellViewModel
    
    private var tap: some Gesture { TapGesture().onEnded { _ in selected.toggle() }}
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnail()
            if viewModel.isEditingMode {
                CheckMarkView(markedSelected: $selected)
                    .offset(x: -5, y: 5)
            }
        }
        .gesture(viewModel.isEditingMode ? tap : nil)
        .onLoad {
            DispatchQueue.global(qos: .utility).async {
                viewModel.loadThumbnail()
            }
        }
    }
    
    @ViewBuilder
    private func thumbnail() -> some View {
        if viewModel.thumbnailContainer.isPlaceholder {
            Color.clear
                .aspectRatio(1, contentMode: .fill)
                .overlay(
                    viewModel.thumbnailContainer.image
                )
        } else {
            viewModel.thumbnailContainer.image
                .resizable()
                .aspectRatio(1, contentMode: .fill)
        }
    }
}
