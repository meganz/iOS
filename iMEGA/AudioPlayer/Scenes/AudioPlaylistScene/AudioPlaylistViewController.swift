import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import UIKit

final class AudioPlaylistViewController: UIViewController {
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
        
        configureNavigationBar()
        configureToolbar()
        
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            setupLiquidGlassNavigationBar(with: TokenColors.Background.page)
        } else {
            guard let navigationBar = navigationController?.navigationBar else { return }
            let currentAppearance = navigationBar.standardAppearance
            currentAppearance.backgroundColor = TokenColors.Background.page
            currentAppearance.shadowColor = .clear
            
            navigationController?.navigationBar.standardAppearance = currentAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = currentAppearance
            navigationController?.navigationBar.compactAppearance = currentAppearance
        }
    }
    
    // MARK: - Private functions
    private func configureToolbar() {
        let removeItem = UIBarButtonItem(
            title: Strings.Localizable.remove,
            style: .plain,
            target: self,
            action: #selector(removeButtonAction(_:))
        )
        
        toolbarItems = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            removeItem
        ]
    }
    
    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: Strings.Localizable.close,
            style: .plain,
            target: self,
            action: #selector(closeButtonAction(_:))
        )
    }
    
    private func showToolbar() {
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    private func hideToolbar() {
        navigationController?.setToolbarHidden(true, animated: true)
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
        tableView.separatorColor = TokenColors.Border.strong
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: animated)
    }
    
    // MARK: - UI actions
    @IBAction func closeButtonAction(_ barButtonItem: UIBarButtonItem) {
        viewModel.dispatch(.dismiss)
    }
    
    @objc func removeButtonAction(_ barButtonItem: UIBarButtonItem) {
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
            navigationItem.title = title
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
