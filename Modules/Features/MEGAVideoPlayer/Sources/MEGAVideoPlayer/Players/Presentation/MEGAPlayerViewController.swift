import AVKit
import MEGADesignToken
import MEGADomain
import MEGAInfrastructure
import MEGAPermissions
import UIKit

public final class MEGAPlayerViewController: UIViewController {
    private let videoView = UIView()
    private let viewModel: MEGAPlayerViewModel
    private var pipController: AVPictureInPictureController?

    private var isPictureInPictureSessionActive: Bool {
        VideoPlayerPictureInPictureSession.isHosted(by: self)
    }

    private var isOffScreen: Bool {
        isBeingDismissed || viewIfLoaded?.window == nil
    }

    private let pictureInPicturePresenter: @MainActor () -> UIViewController?

    public init(
        viewModel: MEGAPlayerViewModel,
        pictureInPicturePresenter: @escaping @MainActor () -> UIViewController?
    ) {
        self.viewModel = viewModel
        self.pictureInPicturePresenter = pictureInPicturePresenter
        super.init(nibName: nil, bundle: nil)
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

        setupDismissAction()
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

    private func setupDismissAction() {
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
                hapticFeedbackUseCase: HapticFeedbackUseCase(),
                didTapBackAction: { [weak self] in
                    self?.dismissPlayer()
                },
                didTapMoreAction: { [weak self] node in
                    self?.viewModel.moreAction?(node)
                },
                didDragToDismissAction: { [weak self] in
                    self?.dismissPlayer()
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
        pipController?.delegate = self
    }

    /// Takes the window down and stops whatever was feeding it
    func endPictureInPictureSession() {
        pipController?.stopPictureInPicture()
        endPlaybackIfOffScreen()
    }

    /// A session that ends with the player nowhere on screen has nothing left to play into, so playback
    /// ends with it. One the user restored — or never left — carries on full screen.
    private func endPlaybackIfOffScreen() {
        guard isOffScreen else { return }

        viewModel.viewWillDismiss()
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

    // MARK: - Dismissal

    /// Shared by the back button and the drag down gesture, so both leave the same way.
    ///
    /// While a Picture in Picture session is running, leaving takes away only the screen: the video
    /// keeps playing in its window until the user closes or restores it.
    private func dismissPlayer() {
        if !isPictureInPictureSessionActive {
            viewModel.viewWillDismiss()
        }

        viewModel.dismissAction?()
    }
}

// MARK: - PictureInPictureHost

extension MEGAPlayerViewController: PictureInPictureHost {}

// MARK: - AVPictureInPictureControllerDelegate

// AVKit calls its delegate on the main thread, so the conformance is main actor isolated even though
// the Objective-C protocol carries no isolation of its own.
extension MEGAPlayerViewController: @preconcurrency AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        VideoPlayerPictureInPictureSession.begin(hostedBy: self)
    }

    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        // A session already torn down on this side — because the next video is opening — has nothing
        // left to restore, and must not put this player back over the one replacing it.
        guard isPictureInPictureSessionActive else {
            completionHandler(false)
            return
        }

        guard isOffScreen else {
            completionHandler(true)
            return
        }

        guard let presenter = pictureInPicturePresenter() else {
            completionHandler(false)
            return
        }

        presenter.present(self, animated: true) { completionHandler(true) }
    }

    public func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        endPlaybackIfOffScreen()
        VideoPlayerPictureInPictureSession.relinquish(by: self)
    }

    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: any Error
    ) {
        // The session counts as running from `willStart`, so a player dismissed during the start
        // transition has already skipped its teardown on the way out, waiting for the window to take
        // over. No window arrived, so it has to happen here.
        endPlaybackIfOffScreen()
        VideoPlayerPictureInPictureSession.relinquish(by: self)
    }
}

// MARK: - SwiftUI View

import SwiftUI

public struct MEGAPlayerView: UIViewControllerRepresentable {
    let viewModel: MEGAPlayerViewModel
    let pictureInPicturePresenter: @MainActor () -> UIViewController?
    @Environment(\.dismiss) private var dismiss

    public init(
        viewModel: MEGAPlayerViewModel,
        pictureInPicturePresenter: @escaping @MainActor () -> UIViewController?
    ) {
        self.viewModel = viewModel
        self.pictureInPicturePresenter = pictureInPicturePresenter
    }

    public func makeUIViewController(context: Context) -> MEGAPlayerViewController {
        viewModel.dismissAction = {
            dismiss()
        }
        let controller = MEGAPlayerViewController(
            viewModel: viewModel,
            pictureInPicturePresenter: pictureInPicturePresenter
        )
        return controller
    }

    public func updateUIViewController(_ uiViewController: MEGAPlayerViewController, context: Context) {}
}

extension UIView: PlayerViewProtocol {}
