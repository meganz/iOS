import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAUIComponent
import Search
import SwiftUI

extension SharedItemsViewController {
    @objc func headerView() -> UIView {
        UIHostingConfiguration {
            SortHeaderViewWrapper(config: viewModel.sortHeaderConfig, sortOrder: viewModel.sortOrder) { [weak self] order in
                self?.viewModel.sortOrder = order
            }
            .simultaneousGesture(TapGesture().onEnded { [weak self] _ in
                self?.viewModel.sortHeaderViewPressed()
            })
        }
        .margins(.all, 0)
        .makeContentView()
    }
    
    @objc func resetSortIfNeeded() {
        guard viewModel.shouldResetSortOrderType() else { return }
        sortOrderType = .defaultAsc
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
