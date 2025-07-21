import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import UIKit

final class RegionListViewController: UIViewController, ViewType {
    // MARK: - Private properties
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "countryCell")
        table.delegate = self
        return table
    }()
    
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.delegate = self
        sc.obscuresBackgroundDuringPresentation = false
        return sc
    }()
    
    private var listSource: (any RegionListSource)? {
        didSet {
            tableView.dataSource = listSource
            tableView.reloadData()
        }
    }
    
    private let viewModel: RegionListViewModel
    
    // MARK: - Init
    init(viewModel: RegionListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configView()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewReady)
        
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = false
    }
    
    // MARK: - Config view
    private func configView() {
        title = Strings.Localizable.chooseYourRegion
        
        view.wrap(tableView)
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        setupColors()
    }
    
    private func setupColors() {
        tableView.backgroundColor = TokenColors.Background.surface1
        tableView.sectionIndexColor = TokenColors.Text.primary
        tableView.separatorColor = TokenColors.Border.strong
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: RegionListViewModel.Command) {
        switch command {
        case .reloadSearchedRegions(let regions):
            listSource = RegionListSearchSource(regions: regions)
        case let .reloadIndexedRegions(indexedRegions, collation):
            listSource = RegionListIndexedSource(indexedRegions: indexedRegions, collation: collation)
        }
    }
}

// MARK: - UITableViewDelegate
extension RegionListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func routeToSelectedRegion() {
            guard let region = listSource?.country(at: indexPath) else { return }
            viewModel.dispatch(.didSelectRegion(region))
        }
        
        if searchController.isActive {
            dismiss(animated: true) {
                routeToSelectedRegion()
            }
        } else {
            routeToSelectedRegion()
        }
    }
}

// MARK: - UISearchResultsUpdating
extension RegionListViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.trim else { return }
        viewModel.dispatch(.startSearching(searchText))
    }
}

// MARK: - UISearchControllerDelegate
extension RegionListViewController: UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        viewModel.dispatch(.finishSearching)
    }
}
