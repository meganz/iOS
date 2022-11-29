import SwiftUI

@available(iOS 16.0, *)
struct PhotoLibraryModeAllCollectionView: View {
    @StateObject var viewModel: PhotoLibraryModeAllCollectionViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotoLibraryCollectionViewRepresenter(viewModel: viewModel)
                .ignoresSafeArea(edges: .bottom)
            PhotoLibraryZoomControl(zoomState: $viewModel.zoomState)
        }
    }
}
