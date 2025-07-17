import Accounts
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwift
import UIKit

class AudioPlayerViewController: UIViewController, AudioPlayerViewControllerNodeActionForwardingDelegate {
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
    private var pendingDragEvent: Bool = false
    private var playerType: PlayerType = .default
    
    private var selectedNodeActionTypeEntity: NodeActionTypeEntity?
    
    // MARK: - Internal properties
    private(set) var viewModel: AudioPlayerViewModel
    
    init?(coder: NSCoder, viewModel: AudioPlayerViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        viewModel.dispatch(.onViewDidLoad)
        navigationController?.delegate = self
        
        configureActivityIndicatorViewColor()
        
        configureImages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed || presentingViewController?.isBeingDismissed == true {
            viewModel.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        } else {
            if let selectedNodeActionTypeEntity, isSelectingSupportedNodeActionType(selectedNodeActionTypeEntity) {
                viewModel.dispatch(.viewWillDisappear(reason: .systemPushedAnotherView))
            } else {
                viewModel.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
            }
            selectedNodeActionTypeEntity = nil
        }
    }
    
    /// Overriding dismiss function to detect dismissal of current view controller triggered from navigation controller's dismissal
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        viewModel.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
    }
    
    deinit {
        MEGALogDebug("[AudioPlayer] deallocating AudioPlayerViewController instance")
        removeDelegates()
    }
    
    // MARK: - Private functions
    
    private func configureImages() {
        imageView.image = MEGAAssets.UIImage.defaultArtwork

        goBackwardButton.setImage(MEGAAssets.UIImage.image(named: "goBackward15"), for: .normal)
        previousButton.setImage(MEGAAssets.UIImage.image(named: "backTrack"), for: .normal)
        playPauseButton.setImage(MEGAAssets.UIImage.image(named: "play"), for: .normal)
        nextButton.setImage(MEGAAssets.UIImage.image(named: "fastForward"), for: .normal)
        goForwardButton.setImage(MEGAAssets.UIImage.image(named: "goForward15"), for: .normal)

        shuffleButton.setImage(MEGAAssets.UIImage.image(named: "shuffleAudio"), for: .normal)
        repeatButton.setImage(MEGAAssets.UIImage.image(named: "repeatAudio"), for: .normal)
        playbackSpeedButton.setImage(MEGAAssets.UIImage.image(named: "normal"), for: .normal)
        gotoplaylistButton.setImage(MEGAAssets.UIImage.image(named: "viewPlaylist"), for: .normal)

        moreButton.setImage(MEGAAssets.UIImage.image(named: "moreNavigationBar"), for: .normal)
    }
    
    private func isSelectingSupportedNodeActionType(_ selectedNodeActionTypeEntity: NodeActionTypeEntity) -> Bool {
        selectedNodeActionTypeEntity == .import
        || selectedNodeActionTypeEntity == .download
    }
    
    private func configureActivityIndicatorViewColor() {
        activityIndicatorView.color = TokenColors.Icon.secondary
    }
    
    private func removeDelegates() {
        if navigationController?.delegate === self {
            navigationController?.delegate = nil
        }
        
        viewModel.dispatch(.removeDelegates)
    }
    
    private func updatePlayerStatus(currentTime: String, remainingTime: String, percentage: Float, isPlaying: Bool) {
        currentTimeLabel.text = currentTime
        remainingTimeLabel.text = remainingTime
        
        updateSliderValueIfNeeded(percentage)
        
        playPauseButton.tintColor = TokenColors.Icon.primary
        playPauseButton.setImage((isPlaying ? MEGAAssets.UIImage.pause : MEGAAssets.UIImage.play).withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate), for: .normal)
        
        if timeSliderView.value == 1.0 {
            timeSliderView.cancelTracking(with: nil)
            if pendingDragEvent {
                pendingDragEvent = false
            }
        }
    }
    
    private func updateSliderValueIfNeeded(_ newValue: Float) {
        guard !pendingDragEvent else { return }
        
        timeSliderView.setValue(newValue, animated: false)
    }
    
    private func updateCurrentItem(name: String, artist: String, thumbnail: UIImage?, nodeSize: String?) {
        titleLabel.text = name
        subtitleLabel.text = artist
        
        if let thumbnailImage = thumbnail {
            imageView.image = thumbnailImage
        } else {
            imageView.image = MEGAAssets.UIImage.defaultArtwork
        }
        
        if let nodeSize = nodeSize {
            detailLabel.text = nodeSize
        }
    }
    
    private func updateRepeat(_ status: RepeatMode) {
        switch status {
        case .none, .loop:
            repeatButton.setImage(MEGAAssets.UIImage.repeatAudio, for: .normal)
        case .repeatOne:
            repeatButton.setImage(MEGAAssets.UIImage.repeatOneAudio, for: .normal)
        }
        updateRepeatButtonAppearance(status: status)
    }
    
    private func updateSpeed(_ mode: SpeedMode) {
        var image: UIImage?
        switch mode {
        case .normal:
            image = MEGAAssets.UIImage.normal
        case .oneAndAHalf:
            image = MEGAAssets.UIImage.oneAndAHalf
        case .double:
            image = MEGAAssets.UIImage.double
        case .half:
            image = MEGAAssets.UIImage.half
        }
        
        image?.withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate)
        
        playbackSpeedButton.setImage(image, for: .normal)
    }
    
    private func updateShuffle(_ status: Bool) {
        updateShuffleButtonAppearance(status: status)
        shuffleButton.isSelected = status
    }
    
    private func updateRepeatButtonAppearance(status: RepeatMode) {
        switch status {
        case .none:
            repeatButton.tintColor = TokenColors.Icon.primary
        case .loop, .repeatOne:
            repeatButton.tintColor = TokenColors.Components.interactive
        }
    }
    
    private func updateShuffleButtonAppearance(status: Bool) {
        shuffleButton.tintColor = status ? TokenColors.Components.interactive : TokenColors.Icon.primary
        shuffleButton.setImage(MEGAAssets.UIImage.shuffleAudio, for: .normal)
    }
    
    private func refreshStateOfLoadingView(_ enabled: Bool) {
        activityIndicatorView.isHidden = !enabled
        if enabled {
            activityIndicatorView.startAnimating()
            hideInfoLabels()
        } else {
            activityIndicatorView.stopAnimating()
            showInfoLabels()
        }
    }
    
    private func hideInfoLabels() {
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
    }
    
    private func showInfoLabels() {
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
    }
    
    private func configureNavigationBar(title: String, subtitle: String) {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close, style: .done, target: self, action: #selector(closeButtonAction))
        
        let rightBarButtonItem = UIBarButtonItem(
            image: MEGAAssets.UIImage.moreNavigationBar,
            style: .plain,
            target: self,
            action: #selector(moreButtonAction(_:))
        )
        
        rightBarButtonItem.tintColor = TokenColors.Icon.primary
        navigationItem.rightBarButtonItem = rightBarButtonItem
        
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
            configureCloseButtonColor()
        }
    }
    
    private func configureCloseButtonColor() {
        closeButton.setTitleColor(TokenColors.Text.primary, for: .normal)
    }
    
    private func updateMoreButtonState() {
        moreButton.isHidden = playerType == .fileLink || playerType == .offline
    }
    
    // MARK: - UI configurations
    private func updateAppearance() {
        updateCloseButtonState()
        updateMoreButtonState()
        style()
        imageView.applyShadow(in: imageViewContainerView, alpha: 0.24, x: 0, y: 1.5, blur: 16, spread: 0)
        
        let playbackControlButtons = [ goBackwardButton, previousButton, playPauseButton, nextButton, goForwardButton ]
        let bottomViewButtons = [ shuffleButton, repeatButton, playbackSpeedButton, gotoplaylistButton ]
        
        playbackControlButtons
            .compactMap { $0 }
            .forEach { [weak self] in self?.setForegroundColor(for: $0, color: TokenColors.Icon.primary) }
        
        bottomViewButtons
            .compactMap { $0 }
            .forEach { [weak self] in self?.setForegroundColor(for: $0, color: TokenColors.Icon.primary) }
    }
    
    private func fileLinkPlayerAppearance() {
        configureViewsColor()
    }
    
    private func defaultPlayerAppearance() {
        configureViewsColor()
        viewModel.dispatch(.refreshRepeatStatus)
        viewModel.dispatch(.refreshShuffleStatus)
    }
    
    private func configureViewsColor() {
        configureBottomViewColor()
        configureViewBackgroundColor()
        configureSeparatorViewColor()
        configureCloseButtonColor()
    }
    
    private func configureBottomViewColor() {
        switch playerType {
        case .default, .offline, .folderLink:
            bottomView.backgroundColor = TokenColors.Background.page
        case .fileLink:
            bottomView.backgroundColor = TokenColors.Background.page
        }
    }
    
    private func configureSeparatorViewColor() {
        switch playerType {
        case .default, .offline, .folderLink:
            separatorView.isHidden = true
        case .fileLink:
            separatorView.backgroundColor = TokenColors.Border.strong
            separatorView.isHidden = false
        }
    }
    
    private func configureViewBackgroundColor() {
        view.backgroundColor = TokenColors.Background.page
    }
    
    private func style() {
        titleLabel.textColor = TokenColors.Text.primary
        subtitleLabel.textColor = TokenColors.Text.secondary
        detailLabel.textColor = TokenColors.Text.secondary
        currentTimeLabel.textColor = TokenColors.Text.secondary
        remainingTimeLabel.textColor = TokenColors.Text.secondary
        timeSliderView.tintColor = TokenColors.Background.surface2
        
        closeButton.titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        configureViewsColor()
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
        guard let phase = event.allTouches?.first?.phase,
              phase == .began || phase == .ended else { return }
        
        pendingDragEvent = (phase == .began)
        if phase == .ended {
            viewModel.dispatch(.updateCurrentTime(percentage: timeSliderView.value))
        }
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
    
    @objc private func closeButtonAction() {
        viewModel.dispatch(.dismiss)
    }
    
    @objc private func moreButtonAction(_ sender: Any) {
        viewModel.dispatch(.showActionsforCurrentNode(sender: sender))
    }
    
    @IBAction func changePlaybackSpeedButtonAction(_ sender: Any) {
        viewModel.dispatch(.onChangeSpeedModePressed)
    }
    
    private func presentAudioPlaybackContinuation(fileName: String, playbackTime: TimeInterval) {
        let alertViewController = UIAlertController(
            title: Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.title,
            message: Strings.Localizable.Media.Audio.PlaybackContinuation
                .Dialog.description(fileName, playbackTime.timeString),
            preferredStyle: .alert
        )
        [
            UIAlertAction(
                title: Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.restart,
                style: .default
            ) { [weak self] _ in
                self?.viewModel.dispatch(.onSelectRestartPlaybackContinuationDialog)
            },
            UIAlertAction(
                title: Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.resume,
                style: .default
            ) { [weak self] _ in
                self?.viewModel.dispatch(
                    .onSelectResumePlaybackContinuationDialog(playbackTime: playbackTime)
                )
            }
        ].forEach { alertViewController.addAction($0) }
        present(alertViewController, animated: true)
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
            configureDefaultPlayer()
        case .configureFileLinkPlayer(let title, let subtitle):
            playerType = .fileLink
            configureFileLinkPlayer(title: title, subtitle: subtitle)
        case .enableUserInteraction(let enabled):
            userInteraction(enabled: enabled)
        case .didPausePlayback, .didResumePlayback:
            setForegroundColor(for: playPauseButton, color: TokenColors.Icon.primary)
        case .shuffleAction(let enabled):
            shuffleButton.isEnabled = enabled
            setForegroundColor(for: shuffleButton, color: enabled ? TokenColors.Icon.primary : TokenColors.Icon.disabled)
        case .goToPlaylistAction(let enabled):
            gotoplaylistButton.isEnabled = enabled
            setForegroundColor(for: gotoplaylistButton, color: enabled ? TokenColors.Icon.primary : TokenColors.Icon.disabled)
        case .nextTrackAction(let enabled):
            nextButton.isEnabled = enabled
            setForegroundColor(for: nextButton, color: enabled ? TokenColors.Icon.primary : TokenColors.Icon.disabled)
        case .displayPlaybackContinuationDialog(let fileName, let playbackTime):
            presentAudioPlaybackContinuation(fileName: fileName, playbackTime: playbackTime)
        }
    }
    
    private func setForegroundColor(for button: UIButton, color: UIColor) {
        button.tintColor = color
        button.setImage(button.currentImage?.withTintColor(color, renderingMode: .alwaysTemplate), for: .normal)
    }
    
    // MARK: - AudioPlayerViewControllerNodeActionForwardingDelegate
    
    func didSelectNodeActionTypeMenu(_ nodeActionTypeEntity: NodeActionTypeEntity) {
        selectedNodeActionTypeEntity = nodeActionTypeEntity
    }
}

// MARK: - Ads
extension AudioPlayerViewController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        SingleItemAsyncSequence(
            item: AdsSlotConfig(displayAds: true)
        ).eraseToAnyAsyncSequence()
    }
}

// MARK: - UINavigationControllerDelegate

extension AudioPlayerViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController != self {
            viewModel.dispatch(.initMiniPlayer)
        }
    }
}
