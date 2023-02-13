import Foundation
import MEGADomain

final class FavouritesViewController: UIViewController, ViewType {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: FavouritesViewModel!
    
    var nodesArray: [NodeEntity] = []
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        configView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.dispatch(.viewWillAppear)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewModel.dispatch(.viewWillDisappear)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - Execute command
    
    func executeCommand(_ command: FavouritesViewModel.Command) {
        switch command {
        case .showFavouritesNodes(let nodes):
            nodesArray = nodes
            tableView.reloadData()
        }
    }
    
    // MARK: - Private
    
    private func configView() {
        tableView.register(UINib(nibName: "GenericNodeTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "GenericNodeTableViewCellID")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
        tableView.emptyDataSetSource = self
    }
    
    private func updateAppearance() {
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
        tableView.backgroundColor = .mnz_backgroundElevated(traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
        
        tableView.reloadData()
    }
}

//MARK: - UITableViewDelegate

extension FavouritesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .mnz_backgroundElevated(traitCollection)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nodeModel = nodesArray[indexPath.row]
        viewModel.dispatch(.didSelectRow(nodeModel.handle))
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK: - UITableViewDataSource

extension FavouritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nodeModel = nodesArray[indexPath.row]
        
        var cell: GenericNodeTableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: "GenericNodeTableViewCellID", for: indexPath) as? GenericNodeTableViewCell
        
        let nodeOpener = NodeOpener(navigationController: navigationController)
        let nodeUseCase = NodeUseCase(nodeDataRepository: NodeDataRepository.newRepo, nodeValidationRepository: NodeValidationRepository.newRepo)
        let accountUseCase = AccountUseCase(repository: AccountRepository(sdk: MEGASdkManager.sharedMEGASdk()))
        
        let cellViewModel = NodeCellViewModel(
            nodeOpener: nodeOpener,
            nodeModel: nodeModel,
            nodeUseCase: nodeUseCase,
            nodeThumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            accountUseCase: accountUseCase
        )
        
        cell?.viewModel = cellViewModel
        cell?.viewModel?.dispatch(.initForReuse)
        
        return cell ?? UITableViewCell()
    }
}

//MARK: - DZNEmptyDataSetSource

extension FavouritesViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        return EmptyStateView.create(for: .favourites)
    }
}
