import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAUIComponent
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

        let sortHeaderViewModel = viewModel.sortHeaderViewModel
        let headerContentView = ResultsHeaderView(leftView: {
            SortHeaderView(viewModel: sortHeaderViewModel)
                .simultaneousGesture(TapGesture().onEnded { [weak self] _ in
                    guard let self else { return }
                    viewModel.sortHeaderViewPressed()
                })
        })

        let hostingViewController = UIHostingController(rootView: headerContentView)
        headerView.wrap(hostingViewController.view)
        addChild(hostingViewController)
        self.headerContainerView = headerView
        hostingViewController.view.backgroundColor = TokenColors.Background.page
        return headerView
    }

    @objc func resetSortIfNeeded() {
        guard SharedItemsViewModel
            .keysToHide(for: selectedTab)
            .contains(currentSortOrder.toUIComponentSortOrderEntity().key) else {
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
            triggerEvent(for: newValue)
            nodesSortTypeHasChanged()
        }
    }

    private func triggerEvent(for sortOrder: MEGADomain.SortOrderEntity) {
        let eventIdentifier: (any EventIdentifier)? =  switch sortOrder {
        case .defaultAsc, .defaultDesc: SortByNameMenuItemEvent()
        case .sizeAsc, .sizeDesc: SortBySizeMenuItemEvent()
        case .creationAsc, .creationDesc: SortByDateAddedMenuItemEvent()
        case .modificationAsc, .modificationDesc: SortByDateModifiedMenuItemEvent()
        case .labelAsc, .labelDesc: SortByLabelMenuItemEvent()
        case .favouriteAsc, .favouriteDesc: SortByFavouriteMenuItemEvent()
        case .linkCreationAsc, .linkCreationDesc: SortByLinkCreationMenuItemEvent()
        case .shareCreationAsc, .shareCreationDesc: SortByShareCreationMenuItemEvent()
        default: nil
        }
        guard let eventIdentifier else { return }
        DIContainer.tracker.trackAnalyticsEvent(with: eventIdentifier)
    }
}
