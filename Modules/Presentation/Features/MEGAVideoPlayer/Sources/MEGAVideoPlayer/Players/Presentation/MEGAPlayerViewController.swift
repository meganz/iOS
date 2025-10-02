import AVKit
import MEGADesignToken
import MEGAPermissions
#if canImport(UIKit)
import UIKit
#endif

public final class MEGAPlayerViewController: UIViewController {
    private let videoView = UIView()
    private let viewModel: MEGAPlayerViewModel
    private var pipController: AVPictureInPictureController?

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
        overrideUserInterfaceStyle = .dark

        setupVideoView()
        setupOverlay()
        viewModel.viewDidLoad(playerView: videoView)
        setupAudioSession()
        setupPictureInPicture()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewModel.viewDidLayoutSubviews(playerView: videoView)
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
        let overlayView = UIHostingConfiguration { [weak self] in
            self?.makeOverlayView()
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

    private func makeOverlayView() -> some View {
        let player = viewModel.player
        return PlayerOverlayView(
            viewModel: PlayerOverlayViewModel(
                player: player,
                devicePermissionsHandler: DevicePermissionsHandler.makeHandler(),
                saveSnapshotUseCase: SaveSnapshotUseCase(),
                didTapBackAction: { [weak self] in
                    self?.viewModel.viewWillDismiss()
                    self?.viewModel.dismissAction?()
                },
                didTapMoreAction: { [weak self] node in
                    self?.viewModel.moreAction?(node)
                },
                didTapRotateAction: { [weak self] in
                    self?.toggleOrientation()
                },
                didTapPictureInPictureAction: { [weak self] in
                    self?.togglePictureInPicture()
                }
            )
        )
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

    private func setupAudioSession() {
        do {
             try AVAudioSession.sharedInstance().setCategory(
                 .playback,
                 mode: .moviePlayback,
                 options: [.allowAirPlay, .allowBluetoothHFP]
             )
             try AVAudioSession.sharedInstance().setActive(true)
         } catch {
             print("Audio session setup failed: \(error)")
         }
    }

    private func setupPictureInPicture() {
        pipController = viewModel.player.loadPIPController()
    }

    // MARK: - Orientation

    private func toggleOrientation() {
        guard let windowScene = view.window?.windowScene else {
            return
        }
        
        let currentOrientation = windowScene.interfaceOrientation
        let targetOrientation: UIInterfaceOrientationMask
        
        if currentOrientation.isPortrait {
            targetOrientation = .landscapeRight
        } else {
            targetOrientation = .portrait
        }
        
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: targetOrientation))
        
        setNeedsUpdateOfSupportedInterfaceOrientations()
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    public override var shouldAutorotate: Bool {
        return true
    }
    
    // MARK: - Picture in Picture

    private func togglePictureInPicture() {
        guard let pipController else { return }

        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
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

extension UIView: PlayerViewProtocol {}

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
