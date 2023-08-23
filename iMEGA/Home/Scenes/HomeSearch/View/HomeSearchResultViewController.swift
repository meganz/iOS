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

    weak var searchHintSelectDelegate: (any HomeSearchControllerDelegate)?

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

// MARK: - MEGASearchControllerEditingDelegate

extension HomeSearchResultViewController: MEGASearchBarViewEditingDelegate {

    func didInputText(_ inputText: String) {
        switch inputText.isEmpty {
        case true:
            viewModel.didHighlightEmptySearchBar()
        case false:
            viewModel.didInputText(text: inputText)
        }
    }

    func didHighlightSearchBar() {
        viewModel.didHighlightEmptySearchBar()
    }

    func didClearText() {
        viewModel.didHighlightEmptySearchBar()
    }
}
