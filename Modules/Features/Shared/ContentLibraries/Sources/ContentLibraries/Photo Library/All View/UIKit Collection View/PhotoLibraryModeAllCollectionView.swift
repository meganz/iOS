import SwiftUI

struct PhotoLibraryModeAllCollectionView: View {
    
    @StateObject var viewModel: PhotoLibraryModeAllCollectionViewModel
    let router: any PhotoLibraryContentViewRouting

    private var isLiquidGlassEnabled: Bool {
        if #available(iOS 26.0, *), ContentLibraries.configuration.featureFlagProvider.isLiquidGlassEnabled() {
            true
        } else {
            false
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotoLibraryCollectionViewRepresenter(viewModel: viewModel, router: router)
                .ignoresSafeArea(edges: isLiquidGlassEnabled ? .vertical : .bottom)
            PhotoLibraryZoomControl(zoomState: $viewModel.zoomState)
                .offset(by: viewModel.photoZoomControlPositionTracker)
        }
    }
}
