import MEGADomain
import MEGASDKRepo

protocol FilesExplorerViewControllerDelegate: AnyObject {
    func updateSearchResults()
    func didScroll(scrollView: UIScrollView)
    func didSelectNodes(withCount count: Int)
    func configureNavigationBarToDefault()
    func showMoreButton(_ show: Bool)
    func showSelectButton(_ show: Bool)
    func audioPlayer(hidden: Bool)
    func updateContextMenu(menu: UIMenu)
    func updateUploadAddMenu(menu: UIMenu)
    func changeCurrentViewType()
    func didSelect(action: UploadAddActionEntity)
}

class FilesExplorerViewController: ExplorerBaseViewController {
    let viewModel: FilesExplorerViewModel
    var configuration: (any FilesExplorerViewConfiguration)?
    weak var delegate: (any FilesExplorerViewControllerDelegate)?
    
    override var displayMode: DisplayMode { .cloudDrive }
    
    init(viewModel: FilesExplorerViewModel,
         delegate: some FilesExplorerViewControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func title() -> String? {
        return configuration?.title
    }
    
    func updateSearchResults(for searchString: String?) {
        viewModel.dispatch(.startSearching(searchString))
    }
    
    func showMoreOptions(forNode node: MEGANode, sender: UIView) {
        guard let navigationController = navigationController else { return }
        
        let backupsUC = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUC.isBackupNode(node.toNodeEntity())
        
        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: navigationController,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController)
        )
        let vc = NodeActionViewController(node: node,
                                          delegate: delegate,
                                          displayMode: .cloudDrive,
                                          isIncoming: false,
                                          isBackupNode: isBackupNode,
                                          sender: sender)
        vc.accessoryActionDelegate = nodeAccessoryActionDelegate
        navigationController.present(vc, animated: true, completion: nil)
    }
    
    func configureView(withSearchText searchText: String?, nodes: [MEGANode]?) {
        if !isToolbarShown {
            delegate?.showMoreButton(nodes?.isEmpty == false)
        }
    }
        
    func toggleSelectAllNodes() {
        fatalError("selectAllNodes() needs to be implemented by the subclass ")
    }
    
    func setEditingMode() {
        fatalError("setEditingMode() needs to be implemented by the subclass")
    }
    
    func configureSearchController(_ searchController: UISearchController) {
        fatalError("configureSearchController(searchController:) needs to be implemented by the subclass")
    }
    
    func removeSearchController(_ searchController: UISearchController) {
        fatalError("removeSearchController(searchController:) needs to be implemented by the subclass")
    }
    
    override func endEditingMode() {
        delegate?.configureNavigationBarToDefault()
    }
    
    func updateContentView(_ height: CGFloat) {
        fatalError("updateContentView(_:) needs to be implemented by the subclass ")
    }
    
    func audioPlayer(hidden: Bool) {
        delegate?.audioPlayer(hidden: hidden)
    }
    
    func updateContextMenu(menu: UIMenu) {
        delegate?.updateContextMenu(menu: menu)
    }
    
    func updateUploadAddMenu(menu: UIMenu) {
        delegate?.updateUploadAddMenu(menu: menu)
    }
}

extension FilesExplorerViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        guard let emptyStateType = configuration?.emptyStateType else { return nil }
        return EmptyStateView.create(for: emptyStateType)
    }
}
