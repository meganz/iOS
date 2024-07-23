import Accounts
import Combine
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import UIKit

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
    private var pendingDragEvent: Bool = false
    private var playerType: PlayerType = .default

    // MARK: - Internal properties
    private(set) var viewModel: AudioPlayerViewModel
    
    init?(coder: NSCoder, viewModel: AudioPlayerViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("You must create this view controller with a user.")
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewDidLoad)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.dispatch(.onViewDidDissapear)
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
    
    override public func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
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
        
        if UIColor.isDesignTokenEnabled() {
            playPauseButton.tintColor = TokenColors.Icon.primary
            playPauseButton.setImage(UIImage(resource: isPlaying ? .pause : .play).withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate), for: .normal)
        } else {
            playPauseButton.setImage(UIImage(resource: isPlaying ? .pause : .play), for: .normal)
        }
        
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
            imageView.image = UIImage(resource: .defaultArtwork)
        }
        
        if let nodeSize = nodeSize {
            detailLabel.text = nodeSize
        }
    }
    
    private func updateRepeat(_ status: RepeatMode) {
        switch status {
        case .none, .loop:
            repeatButton.setImage(UIImage(resource: .repeatAudio), for: .normal)
        case .repeatOne:
            repeatButton.setImage(UIImage(resource: .repeatOneAudio), for: .normal)
        }
        updateRepeatButtonAppearance(status: status)
    }
    
    private func updateSpeed(_ mode: SpeedMode) {
        var image: UIImage?
        switch mode {
        case .normal:
            image = UIImage(resource: .normal)
        case .oneAndAHalf:
            image = UIImage(resource: .oneAndAHalf)
        case .double:
            image = UIImage(resource: .double)
        case .half:
            image = UIImage(resource: .half)
        }
        
        if UIColor.isDesignTokenEnabled() {
            image?.withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate)
        }
        
        playbackSpeedButton.setImage(image, for: .normal)
    }
    
    private func updateShuffle(_ status: Bool) {
        updateShuffleButtonAppearance(status: status)
        shuffleButton.isSelected = status
    }
    
    private func updateRepeatButtonAppearance(status: RepeatMode) {
        switch status {
        case .none:
            repeatButton.tintColor = UIColor.isDesignTokenEnabled()
            ? TokenColors.Icon.primary
            : traitCollection.userInterfaceStyle == .dark ? UIColor.whiteFFFFFF : UIColor.black000000
        case .loop, .repeatOne:
            repeatButton.tintColor = UIColor.isDesignTokenEnabled()
            ? TokenColors.Components.interactive
            : UIColor.green00A382
        }
    }
    
    private func updateShuffleButtonAppearance(status: Bool) {
        if UIColor.isDesignTokenEnabled() {
            shuffleButton.tintColor = status ? TokenColors.Components.interactive : TokenColors.Icon.primary
        } else {
            shuffleButton.tintColor = status ? UIColor.green00A382 : traitCollection.userInterfaceStyle == .dark ? UIColor.whiteFFFFFF : UIColor.black000000
        }
        shuffleButton.setImage(UIImage(resource: .shuffleAudio), for: .normal)
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
            image: UIImage(resource: .moreNavigationBar),
            style: .plain,
            target: self,
            action: #selector(moreButtonAction(_:))
        )
        if UIColor.isDesignTokenEnabled() {
            rightBarButtonItem.tintColor = TokenColors.Icon.primary
        }
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
            configureCloseButtonColor()
        }
    }
    
    private func configureCloseButtonColor() {
        let titleColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.mnz_primaryGray(for: traitCollection)
        closeButton.setTitleColor(titleColor, for: .normal)
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
        
        if UIColor.isDesignTokenEnabled() {
            let playbackControlButtons = [ goBackwardButton, previousButton, playPauseButton, nextButton, goForwardButton ]
            let bottomViewButtons = [ shuffleButton, repeatButton, playbackSpeedButton, gotoplaylistButton ]
            
            playbackControlButtons
                .compactMap { $0 }
                .forEach { [weak self] in self?.setForegroundColor(for: $0, color: TokenColors.Icon.primary) }
            
            bottomViewButtons
                .compactMap { $0 }
                .forEach { [weak self] in self?.setForegroundColor(for: $0, color: TokenColors.Icon.primary) }
        }
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
            bottomView.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.clear
        case .fileLink:
            bottomView.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.mnz_Elevated(traitCollection)
        }
    }
    
    private func configureSeparatorViewColor() {
        switch playerType {
        case .default, .offline, .folderLink:
            separatorView.isHidden = true
        case .fileLink:
            separatorView.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Border.strong : UIColor.mnz_separator(for: traitCollection)
            separatorView.isHidden = false
        }
    }
    
    private func configureViewBackgroundColor() {
        view.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.mnz_backgroundElevated(traitCollection)
    }
    
    private func style(with trait: UITraitCollection) {
        titleLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.label
        subtitleLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : UIColor.label
        detailLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : UIColor.label
        currentTimeLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : UIColor.mnz_secondaryGray(for: trait)
        remainingTimeLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : UIColor.mnz_secondaryGray(for: trait)
        timeSliderView.tintColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.surface2 : UIColor.mnz_gray848484()
        
        closeButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        if UIColor.isDesignTokenEnabled() {
            titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        }
        
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
            configureOfflinePlayer()
        case .configureFileLinkPlayer(let title, let subtitle):
            playerType = .fileLink
            configureFileLinkPlayer(title: title, subtitle: subtitle)
        case .enableUserInteraction(let enabled):
            userInteraction(enabled: enabled)
        case .didPausePlayback:
            if UIColor.isDesignTokenEnabled() {
                setForegroundColor(for: playPauseButton, color: TokenColors.Icon.primary)
            } else {
                playPauseButton.setImage(UIImage(resource: .pause), for: .normal)
            }
        case .didResumePlayback:
            if UIColor.isDesignTokenEnabled() {
                setForegroundColor(for: playPauseButton, color: TokenColors.Icon.primary)
            } else {
                playPauseButton.setImage(UIImage(resource: .play), for: .normal)
            }
        case .shuffleAction(let enabled):
            shuffleButton.isEnabled = enabled
            
            if UIColor.isDesignTokenEnabled() {
                setForegroundColor(for: shuffleButton, color: enabled ? TokenColors.Icon.primary : TokenColors.Icon.disabled)
            } else {
                shuffleButton.tintColor = enabled ? UIColor.black000000 : UIColor.black00000025
            }
            
        case .goToPlaylistAction(let enabled):
            gotoplaylistButton.isEnabled = enabled
            
            if UIColor.isDesignTokenEnabled() {
                setForegroundColor(for: gotoplaylistButton, color: enabled ? TokenColors.Icon.primary : TokenColors.Icon.disabled)
            } else {
                gotoplaylistButton.tintColor = enabled ? UIColor.black000000 : UIColor.black00000025
            }
            
        case .nextTrackAction(let enabled):
            nextButton.isEnabled = enabled
            
            if UIColor.isDesignTokenEnabled() {
                setForegroundColor(for: nextButton, color: enabled ? TokenColors.Icon.primary : TokenColors.Icon.disabled)
            } else {
                nextButton.tintColor = enabled ? UIColor.black000000 : UIColor.black00000025
            }
        case .displayPlaybackContinuationDialog(let fileName, let playbackTime):
            presentAudioPlaybackContinuation(fileName: fileName, playbackTime: playbackTime)
        case .showTermsOfServiceViolationAlert:
            showTermsOfServiceAlert()
        }
    }
    
    private func showTermsOfServiceAlert() {
        let alertController = UIAlertController(
            title: Strings.Localizable.General.Alert.TermsOfServiceViolation.title,
            message: Strings.Localizable.fileLinkUnavailableText2,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: Strings.Localizable.dismiss, style: .default, handler: { [weak viewModel] _ in
            viewModel?.dispatch(.onTermsOfServiceViolationAlertDismissAction)
        }))
        present(alertController, animated: true)
    }
    
    private func setForegroundColor(for button: UIButton, color: UIColor) {
        button.tintColor = color
        button.setImage(button.currentImage?.withTintColor(color, renderingMode: .alwaysTemplate), for: .normal)
    }
}

// MARK: - Ads
extension AudioPlayerViewController: AdsSlotViewControllerProtocol {
    public var adsSlotPublisher: AnyPublisher<AdsSlotConfig?, Never> {
        Just(
            AdsSlotConfig(
                adsSlot: .sharedLink,
                displayAds: true,
                isAdsCookieEnabled: calculateAdCookieStatus
            )
        ).eraseToAnyPublisher()
    }
    
    private func calculateAdCookieStatus() async -> Bool {
        do {
            let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
            let bitmap = try await cookieSettingsUseCase.cookieSettings()
            
            let cookiesBitmap = CookiesBitmap(rawValue: bitmap)
            return cookiesBitmap.contains(.ads) && cookiesBitmap.contains(.adsCheckCookie)
        } catch {
            return false
        }
    }
}
