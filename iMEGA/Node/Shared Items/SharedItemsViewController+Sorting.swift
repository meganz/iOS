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
        guard SharedItemsViewModel
            .keysToHide(for: selectedTab)
            .contains(currentSortOrder.toSearchSortOrderEntity().key) else {
            viewModel.updateSortUI()
            return
        }

        sortOrderType = .defaultAsc
        viewModel.updateSortUI()
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
