import SwiftUI

@available(iOS 16.0, *)
struct PhotoLibraryModeAllCollectionView: View {
    
    @StateObject var viewModel: PhotoLibraryModeAllCollectionViewModel
    let router: any PhotoLibraryContentViewRouting
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotoLibraryCollectionViewRepresenter(viewModel: viewModel, router: router)
                .ignoresSafeArea(edges: .bottom)
            PhotoLibraryZoomControl(zoomState: $viewModel.zoomState)
                .offset(by: viewModel.photoZoomControlPositionTracker)
        }
    }
}
