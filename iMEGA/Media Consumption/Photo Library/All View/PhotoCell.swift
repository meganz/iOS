import SwiftUI

@available(iOS 14.0, *)
struct PhotoCell: View {
    @State private var selected: Bool = false
    @StateObject var viewModel: PhotoCellViewModel
    
    private var tap: some Gesture { TapGesture().onEnded { _ in selected.toggle() }}
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotoCellImage(container: viewModel.thumbnailContainer)
            
            if viewModel.isEditingMode {
                CheckMarkView(markedSelected: $selected)
                    .offset(x: -5, y: 5)
            }
        }
        .gesture(viewModel.isEditingMode ? tap : nil)
        .onAppear {
            viewModel.loadThumbnail()
        }
    }
}

@available(iOS 14.0, *)
extension PhotoCell: Equatable {
    static func == (lhs: PhotoCell, rhs: PhotoCell) -> Bool {
        true // we are taking over the update of the view
    }
}
