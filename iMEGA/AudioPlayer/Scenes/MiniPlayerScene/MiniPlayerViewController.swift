import MEGAAssets
import MEGADesignToken
import MEGAL10n
import UIKit

final class MiniPlayerViewController: UIViewController {
    @IBOutlet weak var progressBarView: MEGAProgressBarView!
    @IBOutlet weak var playPauseButtonImageView: UIImageView!
    @IBOutlet weak var closeButtonImageView: UIButton!
    @IBOutlet weak var closeButtonImage: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - Private properties
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
    private(set) var viewModel: MiniPlayerViewModel
    
    init?(coder: NSCoder, viewModel: MiniPlayerViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateAppearance()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        viewModel.dispatch(.onViewDidLoad)
        
        configureImages()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        updateAppearance()
        progressBarView.setNeedsDisplay()
        
        viewModel.dispatch(.scrollToCurrentItem)
    }
    
    deinit {
        MEGALogDebug("[AudioPlayer] deallocating MiniPlayerViewController instance")
    }
    
    // MARK: - Private functions
    private func configureImages() {
        playPauseButtonImageView.image = MEGAAssets.UIImage.image(named: "miniplayerPause")
        closeButtonImage.image = MEGAAssets.UIImage.image(named: "miniplayerClose")
    }
    
    private func updatePlayback(_ percentage: Float, _ isPlaying: Bool) {
        progressBarView.setProgress(progress: CGFloat(percentage), animated: false)
        
        playPauseButtonImageView.image = (isPlaying ? MEGAAssets.UIImage.miniplayerPause : MEGAAssets.UIImage.miniplayerPlay).withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate)
    }
    
    private func updatePlaybackTracks(_ currentItem: AudioPlayerItem, queue: [AudioPlayerItem]?, loopMode: Bool) {
        miniPlayerSource = MiniPlayerDataSource(currentTrack: currentItem, queue: queue, loopMode: loopMode)
        miniPlayerDelegate = MiniPlayerDelegate(delegate: self, loopMode: loopMode, itemsNumber: queue?.count ?? 0)
        
        Task { @MainActor in
            collectionView.reloadData()
            let indexPath = miniPlayerSource?.indexPath(for: currentItem) ?? IndexPath(row: 0, section: 0)
            scrollToItem(at: indexPath)
        }
    }
    
    private func updateCurrent(indexPath: IndexPath, item: AudioPlayerItem) {
        guard let cell = collectionView.visibleCells.first as? MiniPlayerItemCollectionViewCell,
              let currentItem = cell.item else { return }
        
        guard indexPath.item >= 0, indexPath.item < collectionView.numberOfItems(inSection: indexPath.section) else {
            return
        }
        
        if item != currentItem, lastMovementIndexPath == nil || lastMovementIndexPath != indexPath {
            scrollToItem(at: indexPath)
            lastMovementIndexPath = indexPath
        }
    }
    
    private func updateCurrent(item: AudioPlayerItem) {
        if reloadVisibleCellIfNeeded(for: item) { return }
        guard let index = findTrackIndex(of: item) else { return }
        miniPlayerSource?.tracks?[index] = item
        reloadCell(at: index)
    }

    private func reloadVisibleCellIfNeeded(for item: AudioPlayerItem) -> Bool {
        guard
            let cell = collectionView.visibleCells.first as? MiniPlayerItemCollectionViewCell,
            let path = collectionView.indexPathsForVisibleItems.first,
            cell.item == item
        else {
            return false
        }

        collectionView.reloadItems(at: [path])
        return true
    }

    private func findTrackIndex(of item: AudioPlayerItem) -> Int? {
        guard let tracks = miniPlayerSource?.tracks else { return nil }

        return tracks.firstIndex { optionalTrack in
            guard let track = optionalTrack else { return false }
            if let handle = track.node?.handle, handle == item.node?.handle {
                return true
            }
            return track.url == item.url
        }
    }

    private func reloadCell(at index: Int) {
        let path = IndexPath(row: index, section: 0)
        collectionView.reloadItems(at: [path])
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
    
    private func scrollToItem(at indexPath: IndexPath) {
        Task { @MainActor in
            let section = indexPath.section
            let itemCount = collectionView.numberOfItems(inSection: section)
            
            guard indexPath.item < itemCount else { return }
            
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    // MARK: - UI configurations
    private func updateAppearance() {
        containerView.backgroundColor = TokenColors.Background.surface1
        collectionView.backgroundColor = .clear
        progressBarView.backgroundColor = TokenColors.Background.surface2
        progressBarView.progressColor = TokenColors.Components.selectionControl
        
        topSeparatorView.backgroundColor = TokenColors.Border.strong
        bottomSeparatorView.backgroundColor = TokenColors.Border.strong
        
        playPauseButtonImageView.tintColor = TokenColors.Icon.primary
        
        closeButtonImage.image = MEGAAssets.UIImage.miniplayerClose
            .withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate)
        closeButtonImage.tintColor = TokenColors.Icon.primary
        
        activityIndicatorView.color = TokenColors.Icon.secondary
    }
    
    func refreshPlayer(with config: AudioPlayerConfigEntity) {
        viewModel.dispatch(.refresh(config))
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
        case .scrollToItem(let indexPath):
            scrollToItem(at: indexPath)
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
