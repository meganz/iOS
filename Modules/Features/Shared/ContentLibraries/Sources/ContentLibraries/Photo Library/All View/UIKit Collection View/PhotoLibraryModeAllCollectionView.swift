import SwiftUI

struct PhotoLibraryModeAllCollectionView: View {
    @StateObject private var viewModel: PhotoLibraryModeAllCollectionViewModel
    let router: any PhotoLibraryContentViewRouting

    init(viewModel: @autoclosure @escaping () -> PhotoLibraryModeAllCollectionViewModel, router: some PhotoLibraryContentViewRouting) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.router = router
    }

    private var isLiquidGlassEnabled: Bool {
        if #available(iOS 26.0, *), ContentLibraries.configuration.featureFlagProvider.isLiquidGlassEnabled() {
            true
        } else {
            false
        }
    }

    private var isMediaRevampEnabled: Bool {
        ContentLibraries.configuration.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosMediaRevamp)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotoLibraryCollectionViewRepresenter(viewModel: viewModel, router: router)
                .ignoresSafeArea(edges: isLiquidGlassEnabled ? .vertical : .bottom)
            if !isMediaRevampEnabled {
                PhotoLibraryZoomControl(zoomState: $viewModel.zoomState)
                    .offset(by: viewModel.photoZoomControlPositionTracker)
            }
        }
    }
}
