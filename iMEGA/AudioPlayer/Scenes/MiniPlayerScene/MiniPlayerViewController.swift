import MEGADesignToken
import UIKit

final class MiniPlayerViewController: UIViewController {
    @IBOutlet weak var progressBarView: MEGAProgressBarView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playPauseButtonImageView: UIImageView!
    @IBOutlet weak var closeButtonImageView: UIButton!
    @IBOutlet weak var closeButtonImage: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var containerViewLeadingConstraint: NSLayoutConstraint!
    
    // MARK: - Private properties
    private let containerViewDefaultMargin: CGFloat = 12.0
    private var miniPlayerSource: MiniPlayerDataSource? {
        didSet {
            collectionView.dataSource = miniPlayerSource
        }
    }
    private var miniPlayerDelegate: MiniPlayerDelegate? {
        didSet {
            collectionView.delegate = miniPlayerDelegate
        }
    }
    private var lastMovementIndexPath: IndexPath?
    
    // MARK: - Internal properties
    var viewModel: MiniPlayerViewModel!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateAppearance()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        viewModel.dispatch(.onViewDidLoad)
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        updateAppearance()
        progressBarView.setNeedsDisplay()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let nav = navigationController {
                AppearanceManager.forceNavigationBarUpdate(nav.navigationBar, traitCollection: traitCollection)
            }
            
            updateAppearance()
            collectionView.reloadData()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.updateAppearance()
        })
    }
    
    deinit {
        viewModel.dispatch(.deinit)
    }
    
    // MARK: - Private functions
    private func updatePlayback(_ percentage: Float, _ isPlaying: Bool) {
        progressBarView.setProgress(progress: CGFloat(percentage), animated: false)
        
        playPauseButtonImageView.image = UIImage(resource: isPlaying ? .miniplayerPause : .miniplayerPlay).withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate)
    }
    
    private func updatePlaybackTracks(_ currentItem: AudioPlayerItem, queue: [AudioPlayerItem]?, loopMode: Bool) {
        CrashlyticsLogger.log(category: .audioPlayer, "Setup datasource - player items: \(queue?.count ?? 0)")
        
        miniPlayerSource = MiniPlayerDataSource(currentTrack: currentItem, queue: queue, loopMode: loopMode)
        miniPlayerDelegate = MiniPlayerDelegate(delegate: self, loopMode: loopMode, itemsNumber: queue?.count ?? 0)
        imageView.image = UIImage(resource: .defaultArtwork)
        
        collectionView.reloadData()
        collectionView.performBatchUpdates(nil) { _ in
            let indexPath = IndexPath(row: queue?.firstIndex(of: currentItem) ?? 0, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
        
        CrashlyticsLogger.log(category: .audioPlayer, "After reload - player items : \(collectionView.numberOfItems(inSection: 0))")
    }
    
    private func updateCurrent(indexPath: IndexPath, item: AudioPlayerItem) {
        guard let cell = collectionView.visibleCells.first as? MiniPlayerItemCollectionViewCell,
              let currentItem = cell.item else { return }
        
        guard indexPath.item >= 0, indexPath.item < collectionView.numberOfItems(inSection: indexPath.section) else {
            CrashlyticsLogger.log(category: .audioPlayer, "Attempting to access the indexPath beyond its valid bounds.")
            return
        }
        
        if item != currentItem, lastMovementIndexPath == nil || lastMovementIndexPath == indexPath {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    private func updateCurrent(item: AudioPlayerItem) {
        guard let cell = collectionView.visibleCells.first as? MiniPlayerItemCollectionViewCell,
              let indexPath = collectionView.indexPathsForVisibleItems.first,
              cell.item == item else { return }
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    private func updateCurrent(thumbnail: UIImage?) {
        if let thumbnailImage = thumbnail {
            imageView.image = thumbnailImage
        } else {
            imageView.image = UIImage(resource: .defaultArtwork)
        }
    }
    
    private func userInteraction(enabled: Bool) {
        collectionView.isUserInteractionEnabled = enabled
    }
    
    private func refreshStateOfLoadingView(_ enable: Bool) {
        activityIndicatorView.isHidden = !enable
        enable ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
        playPauseButtonImageView.isHidden = enable
        collectionView.isUserInteractionEnabled = !enable
    }
    
    // MARK: - UI configurations
    private func updateAppearance() {
        view.backgroundColor = TokenColors.Background.surface1
        collectionView.backgroundColor = .clear
        progressBarView.backgroundColor = TokenColors.Background.surface2
        imageView.layer.cornerRadius = 8.0
        
        separatorView.backgroundColor = TokenColors.Border.strong
        separatorHeightConstraint.constant = 0.5
        
        containerViewLeadingConstraint.constant = UIDevice.current.orientation.isLandscape && UIDevice.current.iPhoneDevice ?
        containerViewDefaultMargin + (UIApplication.shared.keyWindow?.safeAreaInsets.left ?? 0.0) : containerViewDefaultMargin
        
        playPauseButtonImageView.tintColor = TokenColors.Icon.primary
        
        closeButtonImage.image = UIImage.miniplayerClose
            .withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate)
        closeButtonImage.tintColor = TokenColors.Icon.primary
        
        activityIndicatorView.color = TokenColors.Icon.secondary
    }
    
    // MARK: - UI actions
    @IBAction func playPauseButtonAction(_ sender: Any) {
        if activityIndicatorView.isHidden {
            viewModel.dispatch(.onPlayPause)
        }
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        viewModel.dispatch(.onClose)
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: MiniPlayerViewModel.Command) {
        switch command {
        case .reloadPlayerStatus(let percentage, let isPlaying):
            updatePlayback(percentage, isPlaying)
        case .reloadNodeInfo(let thumbnail):
            updateCurrent(thumbnail: thumbnail)
        case .reload(let currentItem):
            updateCurrent(item: currentItem)
        case .initTracks(let currentItem, let queue, let loopMode):
            updatePlaybackTracks(currentItem, queue: queue, loopMode: loopMode)
        case .change(let currentItem, let indexPath):
            updateCurrent(indexPath: indexPath, item: currentItem)
        case .showLoading(let show):
            refreshStateOfLoadingView(show)
        case .enableUserInteraction(let enabled):
            userInteraction(enabled: enabled)
        }
    }
}

extension MiniPlayerViewController: MiniPlayerActionsDelegate {
    func play(index: IndexPath) {
        guard let cell = collectionView.cellForItem(at: index) as? MiniPlayerItemCollectionViewCell,
              let item = cell.item else { return }
        
        viewModel.dispatch(.playItem(item))
        
        lastMovementIndexPath = index
    }
    
    func showPlayer(node: MEGANode, filePath: String?) {
        viewModel.dispatch(.showPlayer(node, filePath))
    }
    
    func showPlayer(filePath: String?) {
        viewModel.dispatch(.showPlayer(nil, filePath))
    }
}
