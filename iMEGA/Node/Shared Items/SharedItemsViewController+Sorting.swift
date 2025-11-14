import MEGADomain
import Search
import SwiftUI

extension SharedItemsViewController {
    @objc func headerView() -> UIView {
        guard let headerContainerView else {
            return makeHeaderView()
        }

        return headerContainerView
    }

    private func makeHeaderView() -> UIView {
        let headerView = UIView()
        headerView.bounds = CGRect(x: 0, y: 0, width: 0, height: 40)

        let headerContentView = SearchResultsHeaderView(leftView: {
            let sortHeaderViewModel = viewModel.sortHeaderViewModel
            SearchResultsHeaderSortView(viewModel: sortHeaderViewModel)
        })

        let hostingViewController = UIHostingController(rootView: headerContentView)
        headerView.wrap(hostingViewController.view)
        addChild(hostingViewController)
        self.headerContainerView = headerView
        return headerView
    }

    @objc func resetSortIfNeeded() {
        viewModel.updateSortUI()
        guard viewModel.keysToHide.contains(currentSortOrder.toSearchSortOrderEntity().key) else { return }

        sortOrderType = .defaultAsc
        viewModel.setSortOrderType(sortOrderType)
    }
}

extension SharedItemsViewController: SharedItemsViewing {
    var currentSortOrder: MEGADomain.SortOrderEntity {
        get {
            sortOrderType.toSortOrderEntity()
        }
        set {
            sortOrderType = newValue.toMEGASortOrderType()
            UserDefaults.standard.set(sortOrderType.rawValue, forKey: "SharedItemsSortOrderType")
            nodesSortTypeHasChanged()
        }
    }
}
