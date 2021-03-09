import UIKit

enum PlayerViewType {
    case `default`, offline, fileLink
}

final class AudioPlayerViewController: UIViewController {
    @IBOutlet weak var imageViewContainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dataStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var timeSliderView: MEGASlider!
    @IBOutlet weak var previousButton: MEGAPlayerButton!
    @IBOutlet weak var playPauseButton: MEGAPlayerButton!
    @IBOutlet weak var nextButton: MEGAPlayerButton!
    @IBOutlet weak var shuffleButton: MEGASelectedButton!
    @IBOutlet weak var repeatButton: MEGASelectedButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var gotoplaylistButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    private var toolbarConfigurator: AudioPlayerFileToolbarConfigurator?
    private var shadowLayer: CAShapeLayer?

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
    
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if let navController = navigationController {
                    AppearanceManager.forceNavigationBarUpdate(navController.navigationBar, traitCollection: traitCollection)
                    AppearanceManager.forceToolbarUpdate(navController.toolbar, traitCollection: traitCollection)
                }
                updateAppearance()
            }
        }
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateAppearance()
        })
    }
    
    deinit {
        viewModel.dispatch(.deinit)
    }
    
    // MARK: - Private functions
    private func updatePlayerStatus(currentTime: String, remainingTime: String, percentage: Float, isPlaying: Bool) {
        currentTimeLabel.text = currentTime
        remainingTimeLabel.text = remainingTime
        timeSliderView.value = percentage
        playPauseButton.setImage(isPlaying ? UIImage(named: "pause") : UIImage(named: "play"), for: .normal)
        
        if timeSliderView.value == 1.0 {
            timeSliderView.cancelTracking(with: nil)
        }
    }
    
    private func updateCurrentItem(name: String, artist: String, thumbnail: UIImage?, nodeSize: String?) {
        titleLabel.text = name
        subtitleLabel.text = artist
        
        if let thumbnailImage = thumbnail {
            imageView.image = thumbnailImage
        } else {
            imageView.image = UIImage(named: "defaultArtwork")
        }
        
        if let nodeSize = nodeSize {
            detailLabel.text = nodeSize
        }
    }
    
    private func updateRepeat(_ status: RepeatMode) {
        switch status {
        case .none, .loop:
            repeatButton.setImage(UIImage(named: "repeatAudio"), for: .normal)
        case .repeatOne:
            repeatButton.setImage(UIImage(named: "repeatOneAudio"), for: .normal)
        }
        updateRepeatButtonAppearance(status: status)
    }
    
    private func updateShuffle(_ status: Bool) {
        updateShuffleButtonAppearance(status: status)
        shuffleButton.isSelected = status
    }
    
    private func updateRepeatButtonAppearance(status: RepeatMode) {
        switch status {
        case .none:
            if #available(iOS 12.0, *) {
                repeatButton.tintColor = traitCollection.userInterfaceStyle == .dark ? .white: .black
            } else {
                repeatButton.tintColor = .black
            }
        case .loop, .repeatOne:
            repeatButton.tintColor = UIColor.mnz_green00A382()
        }
    }
    
    private func updateShuffleButtonAppearance(status: Bool) {
        shuffleButton.setTitleColor(UIColor.mnz_green00A382(), for: .selected)
        shuffleButton.setImage(UIImage(named: "shuffleAudio"), for: .normal)
        
        if #available(iOS 12.0, *) {
            shuffleButton.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        } else {
            shuffleButton.tintColor = .black
        }
    }
    
    private func refreshStateOfLoadingView(_ enable: Bool) {
        activityIndicatorView.isHidden = !enable
        if enable {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
    
    private func configureNavigationBar(title: String, subtitle: String) {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("close", comment: "A button label. The button allows the user to close the conversation."), style: .done, target: self, action: #selector(closeButtonAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(moreButtonAction(_:)))
        
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
    
    private func userInteraction(enable: Bool) {
        timeSliderView.isUserInteractionEnabled = enable
        previousButton.isEnabled = enable
        playPauseButton.isEnabled = enable
        nextButton.isEnabled = enable
        if viewModel.playerType != .fileLink {
            shuffleButton.isEnabled = enable
            repeatButton.isEnabled = enable
            gotoplaylistButton.isEnabled = enable
        }
    }
    
    private func showToolbar() {
        toolbarItems = toolbarConfigurator?.toolbarItems()
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    private func configureDefaultPlayer() {
        compactPlayer(active: false)
    }
    
    private func configureOfflinePlayer() {
        configureDefaultPlayer()
        moreButton.isHidden = true
    }
    
    private func configureFileLinkPlayer(title: String, subtitle: String) {
        configureNavigationBar(title: title, subtitle: subtitle)
        configureToolbarButtons()
        showToolbar()
        compactPlayer(active: true)
    }
    
    private func compactPlayer(active: Bool) {
        detailLabel.isHidden = !active
        shuffleButton.alpha = active ? 0.0 : 1.0
        repeatButton.alpha = active ? 0.0 : 1.0
        moreButton.isHidden = active
        gotoplaylistButton.isHidden = active
        shuffleButton.isUserInteractionEnabled = !active
        repeatButton.isUserInteractionEnabled = !active
        dataStackView.alignment = active ? .leading : .center
        
        updateAppearance()
    }
    
    private func updateCloseButtonState() {
        if #available(iOS 13.0, *) {
            closeButton.isHidden = !(UIDevice.current.iPhoneDevice && (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight))
        } else {
            closeButton.isHidden = false
        }
        
        if !closeButton.isHidden {
            closeButton.setTitle(NSLocalizedString("close", comment: "Title for close button"), for: .normal)
            closeButton.setTitleColor(UIColor.mnz_primaryGray(for: traitCollection), for: .normal)
        }
    }
    
    // MARK: - UI configurations
    private func updateAppearance() {
        if viewModel.playerType == .fileLink {
            bottomView.backgroundColor = .mnz_Elevated(traitCollection)
            view.backgroundColor = .mnz_backgroundElevated(traitCollection)
            bottomView.layer.addBorder(edge: .top, color: UIColor.mnz_gray3C3C43().withAlphaComponent(0.29), thickness: 0.5)
        } else {
            view.backgroundColor = .mnz_backgroundElevated(traitCollection)
            viewModel.dispatch(.refreshRepeatStatus)
            viewModel.dispatch(.refreshShuffleStatus)
            updateCloseButtonState()
        }
        
        titleLabel.textColor = UIColor.mnz_label()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        subtitleLabel.textColor = UIColor.mnz_label()
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        
        detailLabel.textColor = UIColor.mnz_label()
        detailLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        currentTimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        currentTimeLabel.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        
        remainingTimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        remainingTimeLabel.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        
        timeSliderView.tintColor = UIColor.mnz_gray848484()
        
        imageView.applyShadow(in: imageViewContainerView, alpha: 0.24, x: 0, y: 1.5, blur: 16, spread: 0)
    }
    
    // MARK: - UI actions
    @IBAction func shuffleButtonAction(_ sender: Any) {
        shuffleButton.isSelected = !(shuffleButton.isSelected)
        viewModel.dispatch(.onShuffle(active: shuffleButton.isSelected))
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
    
    @IBAction func repeatButtonAction(_ sender: Any) {
        viewModel.dispatch(.onRepeatPressed)
    }
    
    @IBAction func goToPlaylistButtonAction(_ sender: Any) {
        viewModel.dispatch(.showPlaylist)
    }
    
    @IBAction func timeSliderValueChangeAction(_ sender: Any) {
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
        viewModel.dispatch(.sendToContact)
    }
    
    private func shareBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.share)
    }
    
    private func importAction() {
        viewModel.dispatch(.import)
    }
    
    private func shareAction() {
        viewModel.dispatch(.share)
    }
    
    @objc private func closeButtonAction() {
        viewModel.dispatch(.dismiss)
    }
    
    @objc private func moreButtonAction(_ sender: Any) {
        viewModel.dispatch(.showActionsforCurrentNode(sender: sender))
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
        case .showLoading(let enable):
            refreshStateOfLoadingView(enable)
        case .updateRepeat(let status):
            updateRepeat(status)
        case .updateShuffle(let status):
            updateShuffle(status)
        case .configureDefaultPlayer:
            configureDefaultPlayer()
        case .configureOfflinePlayer:
            configureOfflinePlayer()
        case .configureFileLinkPlayer(let title, let subtitle):
            configureFileLinkPlayer(title: title, subtitle: subtitle)
        case .enableUserInteraction(let enable):
            userInteraction(enable: enable)
        case .didPausePlayback:
            playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
        case .didResumePlayback:
            playPauseButton.setImage(UIImage(named: "play"), for: .normal)
        }
    }
}
