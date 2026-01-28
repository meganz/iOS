import ContentLibraries
import SwiftUI

/// A wrapper view that prevents VideoListView from re-rendering when unrelated
/// parent view properties change.
///
/// VideoListView manages its own state internally via @StateObject, so it only
/// needs to re-render when the VideoListViewModel reference itself changes.
/// This wrapper implements Equatable to compare view model identity, preventing
/// unnecessary view rebuilds caused by parent state changes (e.g., navigation title updates).
@MainActor
public struct EquatableVideoListView: View, Equatable {
    private let viewModel: VideoListViewModel
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    private let viewModelIdentifier: ObjectIdentifier

    public init(
        viewModel: VideoListViewModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) {
        self.viewModel = viewModel
        self.videoConfig = videoConfig
        self.router = router
        self.viewModelIdentifier = ObjectIdentifier(viewModel)
    }

    nonisolated public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.viewModelIdentifier == rhs.viewModelIdentifier
    }

    public var body: some View {
        VideoListView(
            viewModel: viewModel,
            videoConfig: videoConfig,
            router: router
        )
    }
}
