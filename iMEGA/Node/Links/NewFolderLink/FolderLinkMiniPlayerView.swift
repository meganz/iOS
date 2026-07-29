import FolderLink
import MEGAAudioPlayer
import SwiftUI
import UIKit

/// The mini player docked above the folder link toolbar.
struct FolderLinkMiniPlayerView: View {
    @ObservedObject var viewModel: FolderLinkMiniPlayerViewModel

    let isAudioPlayerRevampEnabled: Bool

    let presenter: () -> UIViewController?

    var body: some View {
        if isAudioPlayerRevampEnabled {
            MEGAMiniPlayerDock(onExpand: expandToFullScreenPlayer)
        } else {
            LegacyFolderLinkMiniPlayerView(viewModel: viewModel)
        }
    }

    private func expandToFullScreenPlayer() {
        MEGAAudioPlayerViewRouter(
            presenter: presenter(),
            actionsHandler: MEGAAudioPlayerActionsHandler.make()
        )
        .showCurrent()
    }
}

struct LegacyFolderLinkMiniPlayerView: View {
    @ObservedObject var viewModel: FolderLinkMiniPlayerViewModel

    var body: some View {
        MiniPlayerContainer(viewModel: viewModel)
            .frame(height: viewModel.showing ? viewModel.height : 0)
    }

    private struct MiniPlayerContainer: UIViewControllerRepresentable {
        @ObservedObject var viewModel: FolderLinkMiniPlayerViewModel

        func makeUIViewController(context: Context) -> UIViewController {
            FolderLinkMiniPlayerViewController(showing: $viewModel.showing, miniPlayerHeight: $viewModel.height)
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    }
}
