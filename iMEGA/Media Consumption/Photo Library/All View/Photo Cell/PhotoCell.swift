import SwiftUI

@available(iOS 14.0, *)
struct PhotoCell: View {
    @StateObject var viewModel: PhotoCellViewModel
    @Environment(\.editMode) var editMode
    
    private var tap: some Gesture { TapGesture().onEnded { _ in
        viewModel.isSelected.toggle()
    }}
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotoCellImage(container: viewModel.thumbnailContainer, aspectRatio: viewModel.currentZoomScaleFactor == 1 ? nil : 1)
            
            if editMode?.wrappedValue.isEditing == true {
                CheckMarkView(markedSelected: viewModel.isSelected)
                    .offset(x: -5, y: 5)
            }
        }
        .gesture(editMode?.wrappedValue.isEditing == true ? tap : nil)
        .onAppear {
            viewModel.loadThumbnailIfNeeded()
        }
    }
}

@available(iOS 14.0, *)
extension PhotoCell: Equatable {
    static func == (lhs: PhotoCell, rhs: PhotoCell) -> Bool {
        true // we are taking over the update of the view
    }
}
