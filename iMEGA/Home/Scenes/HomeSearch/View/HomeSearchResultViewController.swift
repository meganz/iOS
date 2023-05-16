import UIKit

protocol HomeSearchControllerDelegate: AnyObject {
    func didSelect(searchText: String)
}

final class HomeSearchResultViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var viewModel: HomeSearchResultViewModel!

    var resultTableViewDataSource: TableViewProxy<
        HomeSearchResultFileViewModel
    >!

    var hintTableViewDataSource: TableViewProxy<
        HomeSearchHintViewModel
    >!

    weak var searchHintSelectDelegate: HomeSearchControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        disableAdjustingContentInsets(for: tableView)

        viewModel.notifyUpdate = { [weak self] output in
            guard let self = self else { return }

            switch output.viewState {
            case .hints(let searchHints):
                self.reloadItems(searchHints, into: self.hintTableViewDataSource, in: self.tableView)
            case .results(let searchResultState):
                self.reloadItems(searchResultState, into: self.resultTableViewDataSource, in: self.tableView)
            case .didSelectHint(let searchText):
                self.searchHintSelectDelegate?.didSelect(searchText: searchText)
            }
        }
    }

    // MARK: - Configure TableView

    private func reloadItems(
        _ searchResultState: HomeSearchResultState,
        into dataSource: TableViewProxy<HomeSearchResultFileViewModel>,
        in tableView: UITableView
    ) {
        dataSource.attachTo(tableView)
        switch searchResultState {
        case .loading, .empty, .error: break
        case .data(let files):
            self.resultTableViewDataSource.reload(tableView, withData: files)
        }
    }

    private func reloadItems(
        _ searchHints: [HomeSearchHintViewModel],
        into dataSource: TableViewProxy<HomeSearchHintViewModel>,
        in tableView: UITableView
    ) {
        dataSource.attachTo(tableView)
        dataSource.reload(tableView, withData: searchHints, groupsAsc: false, itemsAsc: false)
    }
}

// MARK: - MEGASearchControllerEdittingDelegate

extension HomeSearchResultViewController: MEGASearchBarViewEdittingDelegate {

    func didInputText(_ inputText: String, from searchController: MEGASearchBarView) {
        switch inputText.isEmpty {
        case true:
            viewModel.didHilightEmptySearchBar()
        case false:
            viewModel.didInputText(text: inputText)
        }
    }

    func didHighlightSearchController(_ searchController: MEGASearchBarView) {
        viewModel.didHilightEmptySearchBar()
    }

    func didClearText(for searchController: MEGASearchBarView) {
        viewModel.didHilightEmptySearchBar()
    }
}
