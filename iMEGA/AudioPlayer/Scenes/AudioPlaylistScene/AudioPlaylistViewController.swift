import UIKit

final class AudioPlaylistViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.register(UINib(nibName: "PlaylistHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "PlaylistHeaderFooterView")
            tableView.alwaysBounceVertical = false
            tableView.allowsMultipleSelectionDuringEditing = true
            tableView.setEditing(true, animated: true)
        }
    }
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var toolbarBlurView: UIVisualEffectView!
    @IBOutlet weak var removeButton: UIButton!
    
    // MARK: - Private properties
    private var playlistSource: AudioPlaylistSource? {
        didSet {
            tableView.dataSource = playlistSource
            tableView.reloadData()
        }
    }
    private var playlistDelegate: AudioPlaylistIndexedDelegate? {
        didSet {
            tableView.delegate = playlistDelegate
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let nav = navigationController {
                AppearanceManager.forceNavigationBarUpdate(nav.navigationBar, traitCollection: traitCollection)
            }
            
            updateAppearance()
            reloadData()
        }
    }
    
    deinit {
        viewModel.dispatch(.deinit)
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
        
        selectedIndexPaths?.forEach {
            tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
        }
    }
    
    private func reloadData(item: AudioPlayerItem? = nil) {
        guard let playlistSource = playlistSource else { return }
        var indexPaths: [IndexPath] = []
        
        if let item = item {
            indexPaths = playlistSource.indexPathsOf(item: item) ?? []
        }
        
        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        
        tableView.beginUpdates()
        item != nil ? tableView.reloadRows(at: indexPaths, with: .none) : tableView.reloadData()
        tableView.endUpdates()
        
        let indexesToReload = item != nil ?
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
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
        
        closeButton.setTitle(Strings.Localizable.close, for: .normal)
        
        removeButton.setTitle(Strings.Localizable.remove, for: .normal)
        
        
        
        toolbarView.layer.addBorder(edge: .top, color: UIColor.mnz_gray3C3C43().withAlphaComponent(0.29), thickness: 0.5)
        
        style(with: traitCollection)
    }
    
    private func style(with trait: UITraitCollection) {
        closeButton.titleLabel?.adjustsFontForContentSizeCategory = true
        closeButton.setTitleColor(UIColor.mnz_primaryGray(for: traitCollection), for: .normal)
        removeButton.titleLabel?.adjustsFontForContentSizeCategory = true
        removeButton.setTitleColor(UIColor.mnz_primaryGray(for: traitCollection), for: .normal)
        
        toolbarView.backgroundColor = .clear
        
        toolbarBlurView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        titleLabel.textColor = UIColor.mnz_label()
        
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
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
        case .reload(let item):
            reloadData(item: item)
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
}
