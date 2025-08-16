import MEGADesignToken
#if canImport(UIKit)
import UIKit
#endif

public final class MEGAPlayerViewController: UIViewController {
    private let videoView = UIView()
    private let viewModel: MEGAPlayerViewModel

    public init(viewModel: MEGAPlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupDismiss()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.insetsLayoutMarginsFromSafeArea = false
        view.directionalLayoutMargins = .zero
        view.backgroundColor = .black

        setupVideoView()
        setupOverlay()
        viewModel.viewDidLoad(playerLayer: videoView)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewModel.viewDidLayoutSubviews(playerLayer: videoView)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.viewDidDisappear()
    }

    private func setupDismiss() {
        viewModel.dismissAction = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func setupOverlay() {
        let overlayView = UIHostingConfiguration { [viewModel] in
            let player = viewModel.player
            let dismissAction = viewModel.dismissAction
            PlayerOverlayView(
                viewModel: PlayerOverlayViewModel(
                    player: player,
                    didTapBackAction: dismissAction ?? {}
                )
            )
        }
        .margins(.all, 0)
        .makeContentView()

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupVideoView() {
        videoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoView)
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: - SwiftUI View

import SwiftUI

public struct MEGAPlayerView: UIViewControllerRepresentable {
    let viewModel: MEGAPlayerViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: MEGAPlayerViewModel) {
        self.viewModel = viewModel
    }

    public func makeUIViewController(context: Context) -> MEGAPlayerViewController {
        viewModel.dismissAction = {
            dismiss()
        }
        let controller = MEGAPlayerViewController(
            viewModel: viewModel
        )
        return controller
    }

    public func updateUIViewController(_ uiViewController: MEGAPlayerViewController, context: Context) {}
}

extension UIView: PlayerLayerProtocol {}

#Preview {
    NavigationStack {
        MEGAPlayerView(
            viewModel: MEGAPlayerViewModel(
                player: PreviewVideoPlayer(
                    state: .playing, currentTime: .seconds(12), duration: .seconds(5_678)
                )
            )
        )
    }
}
