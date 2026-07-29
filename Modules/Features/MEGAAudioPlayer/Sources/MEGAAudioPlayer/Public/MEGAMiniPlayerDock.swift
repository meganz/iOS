import SwiftUI

/// Docks the mini player above a SwiftUI host's bottom edge.
public struct MEGAMiniPlayerDock: View {
    @StateObject private var viewModel: MiniPlayerViewModel

    public init(onExpand: @escaping () -> Void) {
        self.init(service: AudioPlaybackService.shared, onExpand: onExpand)
    }

    init(service: any AudioPlaybackServiceProtocol, onExpand: @escaping () -> Void) {
        let viewModel = MiniPlayerViewModel(service: service)
        viewModel.onExpand = onExpand
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        if viewModel.hasActiveSession {
            MiniPlayerView(vm: viewModel)
        }
    }
}
