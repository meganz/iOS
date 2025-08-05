import MEGADesignToken
import MEGAL10n
import UIKit

final class AudioPlaylistViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.register(PlaylistHeaderFooterHostView.self, forHeaderFooterViewReuseIdentifier: "PlaylistHeaderFooterView")
            tableView.alwaysBounceVertical = false
            tableView.allowsMultipleSelectionDuringEditing = true
            tableView.setEditing(true, animated: true)
            tableView.separatorStyle = .none
        }
    }
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var toolbarBlurView: UIVisualEffectView!
    @IBOutlet weak var removeButton: UIButton!
    
    // MARK: - Private properties
    private var playlistSource: (any AudioPlaylistSource)? {
        didSet {
            tableView.dataSource = playlistSource
            tableView.reloadData()
        }
    }
    private var playlistDelegate: AudioPlaylistIndexedDelegate? {
        didSet {
            tableView.delegate = playlistDelegate
            tableView.dragDelegate = playlistDelegate
        }
    }
    
    // MARK: - Internal properties
    var viewModel: AudioPlaylistViewModel!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateAppearance()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewDidLoad)
        playlistDelegate = AudioPlaylistIndexedDelegate(delegate: self, traitCollection: traitCollection)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.dispatch(.onViewWillDisappear)
    }
    
    // MARK: - Private functions
    private func showToolbar() {
        if toolbarView.isHidden {
            toolbarView.isHidden = false
            
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 1.0,
                           options: .curveEaseInOut,
                           animations: {
                self.toolbarBottomConstraint.constant = 0
                self.toolbarView.layoutIfNeeded()
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.toolbarView.frame.height, right: 0)
            })
        }
    }
    
    private func hideToolbar() {
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let duration: CGFloat = 0.5
        let delay: CGFloat = 0.0
        let damping: CGFloat = 1.0
        let velocity: CGFloat = 1.0
        let option: UIView.AnimationOptions = .curveEaseInOut
        
        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: damping,
                       initialSpringVelocity: velocity,
                       options: option) {
            let height: CGFloat = self.toolbarView.frame.height
            self.toolbarBottomConstraint.constant = height * -1
            self.toolbarView.layoutIfNeeded()
        } completion: { _ in
            self.toolbarView.isHidden = true
        }
    }
    
    private func updateDataSource(_ currentTrack: AudioPlayerItem, _ queueTracks: [AudioPlayerItem]?, _ selectedIndexPaths: [IndexPath]?) {
        playlistSource = AudioPlaylistIndexedSource(currentTrack: currentTrack, queue: queueTracks, delegate: self)
        
        tableView.beginUpdates()
        tableView.reloadData()
        tableView.endUpdates()
        
        /// Deselect the currently playing track if it was selected. The current track should not be selectable.
        let currentTrackIndexPath = IndexPath(row: 0, section: 0)
        if selectedIndexPaths?.contains(currentTrackIndexPath) == true {
            tableView.deselectRow(at: currentTrackIndexPath, animated: false)
        }
        
        selectedIndexPaths?.forEach {
            tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
        }
        
        if tableView.indexPathsForSelectedRows?.isEmpty ?? true {
            hideToolbar()
        }
    }
    
    private func reloadData(items: [AudioPlayerItem]) {
        guard let playlistSource = playlistSource else { return }
    
        let indexPaths = items.flatMap(playlistSource.indexPathsOf)
        
        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        
        UIView.performWithoutAnimation {
            items.isNotEmpty ? tableView.reloadRows(at: indexPaths, with: .none) : tableView.reloadData()
        }
        
        let indexesToReload = items.isNotEmpty ?
        Array(Set(selectedIndexPaths ?? []).intersection(Set(indexPaths))) : selectedIndexPaths
        
        indexesToReload?.forEach {
            tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
        }
    }
    
    private func enableUserInteraction() {
        tableView.isUserInteractionEnabled = true
    }
    
    private func disableUserInteraction() {
        tableView.isUserInteractionEnabled = false
    }
    
    // MARK: - UI configurations
    private func updateAppearance() {
        view.backgroundColor = TokenColors.Background.page
        
        closeButton.setTitle(Strings.Localizable.close, for: .normal)
        
        removeButton.setTitle(Strings.Localizable.remove, for: .normal)
        
        toolbarView.layer.addBorder(
            edge: .top,
            color: TokenColors.Border.strong,
            thickness: 0.5
        )
        
        style()
    }
    
    private func style() {
        closeButton.titleLabel?.adjustsFontForContentSizeCategory = true
        closeButton.setTitleColor(TokenColors.Text.primary, for: .normal)
        removeButton.titleLabel?.adjustsFontForContentSizeCategory = true
        removeButton.setTitleColor(TokenColors.Text.primary, for: .normal)
        
        toolbarView.backgroundColor = TokenColors.Background.surface1
        
        toolbarBlurView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        titleLabel.textColor = TokenColors.Text.primary
        
        tableView.separatorColor = TokenColors.Border.strong
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: animated)
    }
    
    // MARK: - UI actions
    @IBAction func closeButtonAction(_ sender: Any) {
        viewModel.dispatch(.dismiss)
    }
    
    @IBAction func removeButtonAction(_ sender: Any) {
        viewModel.dispatch(.removeSelectedItems)
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: AudioPlaylistViewModel.Command) {
        switch command {
        case .reloadTracks(let currentTrack, let queueTracks, let selectedIndexPaths):
            updateDataSource(currentTrack, queueTracks, selectedIndexPaths)
        case .reload(let items):
            reloadData(items: items)
        case .title(let title):
            titleLabel.text = title
        case .deselectAll:
            tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: false) }
            if tableView.numberOfRows(inSection: 1) == 0 && tableView.indexPathsForSelectedRows?.isEmpty ?? true {
                hideToolbar()
            }
        case .showToolbar:
            showToolbar()
        case .hideToolbar:
            if tableView.indexPathsForSelectedRows?.isEmpty ?? true {
                hideToolbar()
            }
        case .enableUserInteraction:
            enableUserInteraction()
        case .disableUserInteraction:
            disableUserInteraction()
        }
    }
}

extension AudioPlaylistViewController: AudioPlaylistSourceDelegate, AudioPlaylistDelegate {
    
    func move(item: AudioPlayerItem, position: IndexPath, direction: MovementDirection) {
        viewModel.dispatch(.move(item, position, direction))
    }
    
    func didSelect(item: AudioPlayerItem) {
        viewModel.dispatch(.didSelect(item))
    }
    
    func didDeselect(item: AudioPlayerItem) {
        viewModel.dispatch(.didDeselect(item))
    }
    
    func draggWillBegin() {
        viewModel.dispatch(.willDraggBegin)
    }
    
    func draggDidEnd() {
        viewModel.dispatch(.didDraggEnd)
    }
}
