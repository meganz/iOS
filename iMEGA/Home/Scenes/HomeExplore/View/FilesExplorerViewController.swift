
protocol FilesExplorerViewControllerDelegate: AnyObject {
    func updateSearchResults()
    func didScroll(scrollView: UIScrollView)
    func didSelectNodes(withCount count: Int)
    func configureNavigationBarToDefault()
    func showMoreButton(_ show: Bool)
}

class FilesExplorerViewController: ExplorerBaseViewController {
    let viewModel: FilesExplorerViewModel
    var configuration: FilesExplorerViewConfiguration?
    weak var delegate: FilesExplorerViewControllerDelegate?
    
    init(viewModel: FilesExplorerViewModel,
         delegate: FilesExplorerViewControllerDelegate) {
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
        
        let delegate = NodeActionViewControllerGenericDelegate(viewController: navigationController)
        let vc = NodeActionViewController(node: node,
                                          delegate: delegate,
                                          displayMode: .cloudDrive,
                                          isIncoming: false,
                                          sender: sender)
        navigationController.present(vc, animated: true, completion: nil)
    }
    
    func configureView(withSearchText searchText: String?, nodes: [MEGANode]?) {
        delegate?.showMoreButton(nodes?.isEmpty == false)
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
}


extension FilesExplorerViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        guard let emptyStateViewModel = configuration?.emptyStateViewModel else { return nil }
        return EmptyStateView(emptyStateViewModel: emptyStateViewModel)
    }
}
