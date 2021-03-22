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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
      super.viewWillTransition(to: size, with: coordinator)
      tableView.reloadData()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                if navigationController != nil {
                    AppearanceManager.forceNavigationBarUpdate(navigationController!.navigationBar, traitCollection: traitCollection)
                }
                
                updateAppearance()
            }
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
                                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.toolbarView.frame.height, right: 0);
            })
        }
    }
    
    private func hideToolbarIfNeeded() {
        if tableView.indexPathsForSelectedRows?.isEmpty ?? true {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
            
            UIView.animate(withDuration: 0.5,
                             delay: 0,
                             usingSpringWithDamping: 1.0,
                             initialSpringVelocity: 1.0,
                             options: .curveEaseInOut) {
                    self.toolbarBottomConstraint.constant = self.toolbarView.frame.height * -1
                self.toolbarView.layoutIfNeeded()
            } completion: { _ in
                self.toolbarView.isHidden = true
            }
        }
    }
    
    private func updateDataSource(_ currentTrack: AudioPlayerItem, _ queueTracks: [AudioPlayerItem]?) {
        playlistSource = AudioPlaylistIndexedSource(currentTrack: currentTrack, queue: queueTracks, delegate: self)
        tableView.reloadData()
    }
    
    private func reload(_ item: AudioPlayerItem) {
        guard let playlistSource = playlistSource, let indexPaths = playlistSource.indexPathsOf(item: item) else { return }
        tableView.reloadRows(at: indexPaths, with: .none)
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
        
        closeButton.setTitle(NSLocalizedString("close", comment: "Title for close button"), for: .normal)
        closeButton.setTitleColor(UIColor.mnz_primaryGray(for: traitCollection), for: .normal)
        
        removeButton.setTitle(NSLocalizedString("remove", comment: "Title for remove button"), for: .normal)
        removeButton.setTitleColor(UIColor.mnz_primaryGray(for: traitCollection), for: .normal)
        
        toolbarView.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            toolbarBlurView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            toolbarBlurView.effect = UIBlurEffect(style: .extraLight)
        }
        toolbarView.layer.addBorder(edge: .top, color: UIColor.mnz_gray3C3C43().withAlphaComponent(0.29), thickness: 0.5)
        
        titleLabel.textColor = UIColor.mnz_label()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingMiddle
        
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
        case .reloadTracks(let currentTrack, let queueTracks):
            updateDataSource(currentTrack, queueTracks)
        case .reload(let item):
            reload(item)
        case .title(let title):
            titleLabel.text = title
        case .deselectAll:
            tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: true) }
            if tableView.numberOfRows(inSection: 1) == 0 {
                hideToolbarIfNeeded()
            }
        case .showToolbar:
            showToolbar()
        case .hideToolbar:
            hideToolbarIfNeeded()
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
