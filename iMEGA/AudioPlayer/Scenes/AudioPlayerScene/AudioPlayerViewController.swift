import UIKit

enum PlayerViewType {
    case `default`, offline, fileLink
}

final class AudioPlayerViewController: UIViewController {
    @IBOutlet weak var imageViewContainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dataStackView: UIStackView!
    @IBOutlet weak var titleLabel: MEGALabel!
    @IBOutlet weak var subtitleLabel: MEGALabel!
    @IBOutlet weak var detailLabel: MEGALabel!
    @IBOutlet weak var currentTimeLabel: MEGALabel!
    @IBOutlet weak var remainingTimeLabel: MEGALabel!
    @IBOutlet weak var timeSliderView: MEGASlider! {
        didSet {
            timeSliderView.minimumValue = 0
            timeSliderView.maximumValue = 1
        }
    }
    @IBOutlet weak var goBackwardButton: MEGAPlayerButton!
    @IBOutlet weak var previousButton: MEGAPlayerButton!
    @IBOutlet weak var playPauseButton: MEGAPlayerButton!
    @IBOutlet weak var nextButton: MEGAPlayerButton!
    @IBOutlet weak var goForwardButton: MEGAPlayerButton!
    @IBOutlet weak var shuffleButton: MEGASelectedButton!
    @IBOutlet weak var repeatButton: MEGASelectedButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var gotoplaylistButton: UIButton!
    @IBOutlet weak var playbackSpeedButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var separatorView: UIView!
    
    private var toolbarConfigurator: AudioPlayerFileToolbarConfigurator?
    private var shadowLayer: CAShapeLayer?
    private var pendingDragEvent: Bool = false
    private var playerType: PlayerType = .default

    // MARK: - Internal properties
    var viewModel: AudioPlayerViewModel!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewDidLoad)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.dispatch(.initMiniPlayer)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let navController = navigationController {
                AppearanceManager.forceNavigationBarUpdate(navController.navigationBar, traitCollection: traitCollection)
                AppearanceManager.forceToolbarUpdate(navController.toolbar, traitCollection: traitCollection)
            }
            style(with: traitCollection)
        }
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let `self` = self else { return }
            self.style(with: self.traitCollection)
        })
    }
    
    deinit {
        viewModel.dispatch(.deinit)
    }
    
    // MARK: - Private functions
    private func updatePlayerStatus(currentTime: String, remainingTime: String, percentage: Float, isPlaying: Bool) {
        currentTimeLabel.text = currentTime
        remainingTimeLabel.text = remainingTime
        timeSliderView.setValue(percentage, animated: false)
        playPauseButton.setImage(isPlaying ? Asset.Images.AudioPlayer.pause.image : Asset.Images.AudioPlayer.play.image, for: .normal)
        
        if timeSliderView.value == 1.0 {
            timeSliderView.cancelTracking(with: nil)
            if pendingDragEvent {
                viewModel.dispatch(.progressDragEventEnded)
                pendingDragEvent = false
            }
        }
    }
    
    private func updateCurrentItem(name: String, artist: String, thumbnail: UIImage?, nodeSize: String?) {
        titleLabel.text = name
        subtitleLabel.text = artist
        
        if let thumbnailImage = thumbnail {
            imageView.image = thumbnailImage
        } else {
            imageView.image = Asset.Images.AudioPlayer.defaultArtwork.image
        }
        
        if let nodeSize = nodeSize {
            detailLabel.text = nodeSize
        }
    }
    
    private func updateRepeat(_ status: RepeatMode) {
        switch status {
        case .none, .loop:
            repeatButton.setImage(Asset.Images.AudioPlayer.repeatAudio.image, for: .normal)
        case .repeatOne:
            repeatButton.setImage(Asset.Images.AudioPlayer.repeatOneAudio.image, for: .normal)
        }
        updateRepeatButtonAppearance(status: status)
    }
    
    private func updateSpeed(_ mode: SpeedMode) {
        switch mode {
        case .normal:
            playbackSpeedButton.setImage(Asset.Images.AudioPlayer.SpeedMode.normal.image, for: .normal)
        case .oneAndAHalf:
            playbackSpeedButton.setImage(Asset.Images.AudioPlayer.SpeedMode.oneAndAHalf.image, for: .normal)
        case .double:
            playbackSpeedButton.setImage(Asset.Images.AudioPlayer.SpeedMode.double.image, for: .normal)
        case .half:
            playbackSpeedButton.setImage(Asset.Images.AudioPlayer.SpeedMode.half.image, for: .normal)
        }
    }
    
    private func updateShuffle(_ status: Bool) {
        updateShuffleButtonAppearance(status: status)
        shuffleButton.isSelected = status
    }
    
    private func updateRepeatButtonAppearance(status: RepeatMode) {
        switch status {
        case .none:
            repeatButton.tintColor = traitCollection.userInterfaceStyle == .dark ? .white: .black
        case .loop, .repeatOne:
            repeatButton.tintColor = UIColor.mnz_green00A382()
        }
    }
    
    private func updateShuffleButtonAppearance(status: Bool) {
        shuffleButton.tintColor = status ? Colors.General.Green._00A382.color : traitCollection.userInterfaceStyle == .dark ? .white : .black
        shuffleButton.setImage(Asset.Images.AudioPlayer.shuffleAudio.image, for: .normal)
    }
    
    private func refreshStateOfLoadingView(_ enabled: Bool) {
        activityIndicatorView.isHidden = !enabled
        if enabled {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
    
    private func configureNavigationBar(title: String, subtitle: String) {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close, style: .done, target: self, action: #selector(closeButtonAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, style: .plain, target: self, action: #selector(moreButtonAction(_:)))
        
        let titleView = CustomTitleView.instanceFromNib
        titleView.titleLabel.text = title
        titleView.subtitleLabel.text = subtitle
        navigationItem.titleView = titleView
    }
    
    private func configureToolbarButtons() {
        if toolbarConfigurator == nil {
            toolbarConfigurator = AudioPlayerFileToolbarConfigurator(
                importAction: importBarButtonPressed,
                sendToContactAction: sendToContactBarButtonPressed,
                shareAction: shareBarButtonPressed
            )
        }
    }
    
    private func userInteraction(enabled: Bool) {
        timeSliderView.isUserInteractionEnabled = enabled
        goBackwardButton.isEnabled = enabled
        previousButton.isEnabled = enabled
        playPauseButton.isEnabled = enabled
        nextButton.isEnabled = enabled
        goForwardButton.isEnabled = enabled
        if playerType != .fileLink {
            shuffleButton.isEnabled = enabled
            repeatButton.isEnabled = enabled
            gotoplaylistButton.isEnabled = enabled
            playbackSpeedButton.isEnabled = enabled
        }
    }
    
    private func showToolbar() {
        toolbarItems = toolbarConfigurator?.toolbarItems()
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    private func configureDefaultPlayer() {
        compactPlayer(active: false)
        defaultPlayerAppearance()
        updateAppearance()
    }
    
    private func configureOfflinePlayer() {
        configureDefaultPlayer()
    }
    
    private func configureFileLinkPlayer(title: String, subtitle: String) {
        configureNavigationBar(title: title, subtitle: subtitle)
        configureToolbarButtons()
        showToolbar()
        compactPlayer(active: true)
        fileLinkPlayerAppearance()
        updateAppearance()
    }
    
    private func compactPlayer(active: Bool) {
        detailLabel.isHidden = !active
        shuffleButton.alpha = active ? 0.0 : 1.0
        repeatButton.alpha = active ? 0.0 : 1.0
        gotoplaylistButton.isHidden = active
        shuffleButton.isUserInteractionEnabled = !active
        repeatButton.isUserInteractionEnabled = !active
        dataStackView.alignment = active ? .leading : .center
        toolbarView.isHidden = active
        navigationController?.isNavigationBarHidden = !active
    }
    
    private func updateCloseButtonState() {
        closeButton.isHidden = playerType == .fileLink
        
        if !closeButton.isHidden {
            closeButton.setTitle(Strings.Localizable.close, for: .normal)
            closeButton.setTitleColor(UIColor.mnz_primaryGray(for: traitCollection), for: .normal)
        }
    }
    
    private func updateMoreButtonState() {
        moreButton.isHidden = playerType == .fileLink || playerType == .offline
    }
    
    // MARK: - UI configurations
    private func updateAppearance() {
        updateCloseButtonState()
        updateMoreButtonState()
        style(with: traitCollection)
        imageView.applyShadow(in: imageViewContainerView, alpha: 0.24, x: 0, y: 1.5, blur: 16, spread: 0)
    }
    
    private func fileLinkPlayerAppearance() {
        bottomView.backgroundColor = .mnz_Elevated(traitCollection)
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
        separatorView.isHidden = false
        separatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
    }
    
    private func defaultPlayerAppearance() {
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
        bottomView.backgroundColor = .clear
        viewModel.dispatch(.refreshRepeatStatus)
        viewModel.dispatch(.refreshShuffleStatus)
        separatorView.isHidden = true
    }
    
    private func style(with trait: UITraitCollection) {
        titleLabel.textColor = UIColor.mnz_label()
        subtitleLabel.textColor = UIColor.mnz_label()
        detailLabel.textColor = UIColor.mnz_label()
        currentTimeLabel.textColor = UIColor.mnz_secondaryGray(for: trait)
        remainingTimeLabel.textColor = UIColor.mnz_secondaryGray(for: trait)
        timeSliderView.tintColor = UIColor.mnz_gray848484()
        
        closeButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }
    
    // MARK: - UI actions
    @IBAction func shuffleButtonAction(_ sender: Any) {
        shuffleButton.isSelected = !(shuffleButton.isSelected)
        viewModel.dispatch(.onShuffle(active: shuffleButton.isSelected))
    }
    
    @IBAction func goBackwardsButtonAction(_ sender: Any) {
        viewModel.dispatch(.onGoBackward)
    }
    
    @IBAction func previousButtonAction(_ sender: Any) {
        viewModel.dispatch(.onPrevious)
    }
    
    @IBAction func playPauseButtonAction(_ sender: Any) {
        viewModel.dispatch(.onPlayPause)
    }
    
    @IBAction func nextButtonAction(_ sender: Any) {
        viewModel.dispatch(.onNext)
    }
    
    @IBAction func goForwardButtonAction(_ sender: Any) {
        viewModel.dispatch(.onGoForward)
    }
    
    @IBAction func repeatButtonAction(_ sender: Any) {
        viewModel.dispatch(.onRepeatPressed)
    }
    
    @IBAction func goToPlaylistButtonAction(_ sender: Any) {
        viewModel.dispatch(.showPlaylist)
    }
    
    @IBAction func timeSliderValueChangeAction(_ sender: Any, forEvent event: UIEvent) {
        guard let touchEvent = event.allTouches?.first else { return }
        switch touchEvent.phase {
        case .began:
            viewModel.dispatch(.progressDragEventBegan)
            pendingDragEvent = true
        case .ended:
            viewModel.dispatch(.progressDragEventEnded)
            pendingDragEvent = false
        default: break
        }
        
        viewModel.dispatch(.updateCurrentTime(percentage: timeSliderView.value))
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        viewModel.dispatch(.showActionsforCurrentNode(sender: sender))
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        closeButtonAction()
    }
    
    private func importBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.import)
    }
    
    private func sendToContactBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.sendToChat)
    }
    
    private func shareBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.share(sender: button))
    }
    
    private func importAction() {
        viewModel.dispatch(.import)
    }
    
    private func shareAction(sender: UIBarButtonItem) {
        viewModel.dispatch(.share(sender: sender))
    }
    
    @objc private func closeButtonAction() {
        viewModel.dispatch(.dismiss)
    }
    
    @objc private func moreButtonAction(_ sender: Any) {
        viewModel.dispatch(.showActionsforCurrentNode(sender: sender))
    }
    
    @IBAction func changePlaybackSpeedButtonAction(_ sender: Any) {
        viewModel.dispatch(.onChangeSpeedModePressed)
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: AudioPlayerViewModel.Command) {
        switch command {
        case .reloadPlayerStatus(let currentTime, let remainingTime, let percentage, let isPlaying):
            updatePlayerStatus(currentTime: currentTime, remainingTime: remainingTime, percentage: percentage, isPlaying: isPlaying)
        case .reloadNodeInfo(let name, let artist, let thumbnail, let nodeSize):
            updateCurrentItem(name: name, artist: artist, thumbnail: thumbnail, nodeSize: nodeSize)
        case .reloadThumbnail(let thumbnail):
            imageView.image = thumbnail
        case .showLoading(let enabled):
            timeSliderView.isUserInteractionEnabled = !enabled
            refreshStateOfLoadingView(enabled)
        case .updateRepeat(let status):
            updateRepeat(status)
        case .updateSpeed(let mode):
            updateSpeed(mode)
        case .updateShuffle(let status):
            updateShuffle(status)
        case .configureDefaultPlayer:
            playerType = .`default`
            configureDefaultPlayer()
        case .configureOfflinePlayer:
            playerType = .offline
            configureOfflinePlayer()
        case .configureFileLinkPlayer(let title, let subtitle):
            playerType = .fileLink
            configureFileLinkPlayer(title: title, subtitle: subtitle)
        case .enableUserInteraction(let enabled):
            userInteraction(enabled: enabled)
        case .didPausePlayback:
            playPauseButton.setImage(Asset.Images.AudioPlayer.pause.image, for: .normal)
        case .didResumePlayback:
            playPauseButton.setImage(Asset.Images.AudioPlayer.play.image, for: .normal)
        case .shuffleAction(let enabled):
            shuffleButton.isEnabled = enabled
            shuffleButton.tintColor = enabled ? .black : UIColor.black.withAlphaComponent(0.25)
        case .goToPlaylistAction(let enabled):
            gotoplaylistButton.isEnabled = enabled
            gotoplaylistButton.tintColor = enabled ? .black : UIColor.black.withAlphaComponent(0.25)
        case .nextTrackAction(let enabled):
            nextButton.isEnabled = enabled
            nextButton.tintColor = enabled ? .black : UIColor.black.withAlphaComponent(0.25)
        }
    }
}
