import MEGAAppSDKRepo
import MEGAConnectivity
import MEGADomain
import SwiftUI

// Applies noInternetViewModifier only when iPhone is in portrait mode (verticalSizeClass != .compact).
// Uses NetworkPathConnectionUseCase (same NWPathMonitor as HomeViewModel, no debounce, no health-check polling)
// instead of the default DependencyInjection.noInternetViewModel which uses ConnectivityMonitorAdapter.
struct HomeLandscapeNoInternetViewModifier: ViewModifier {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @StateObject private var viewModel = NoInternetViewModel(
        connectionUseCase: NetworkPathConnectionUseCase(
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo)
        )
    )

    func body(content: Content) -> some View {
        if verticalSizeClass == .compact {
            content
        } else {
            content.modifier(
                NoInternetViewModifier(
                    layout: .onTop,
                    viewModel: viewModel
                )
            )
        }
    }
}
