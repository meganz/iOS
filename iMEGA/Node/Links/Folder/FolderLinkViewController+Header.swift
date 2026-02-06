import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import Search
import SwiftUI

extension FolderLinkViewController {
    private var currentSortOrder: MEGADomain.SortOrderEntity {
        get {
            Helper.sortType(for: parentNode).toSortOrderEntity()
        }
        set {
            Helper.save(newValue.toMEGASortOrderType(), for: parentNode)
            triggerEvent(for: newValue)
            refreshResults(false)
        }
    }

    var sortHeaderConfig: SortHeaderConfig {
        let keys: [MEGAUIComponent.SortOrder.Key] = [
            .name, .favourite, .label, .lastModified, .size
        ]
        return SortHeaderConfig(
            title: Strings.Localizable.sortTitle,
            options: keys.sortOptions
        )
    }

    var shouldShowHeaderView: Bool {
        DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosCloudDriveRevamp)
    }

    func headerView(for controller: some FolderLinkViewHosting) -> UIView {
        guard let headerContainerView = controller.headerContainerView else {
            return makeHeaderView(controller: controller)
        }

        return headerContainerView
    }

    private func makeHeaderView(controller: some FolderLinkViewHosting) -> UIView {
        let headerView = UIView()
        headerView.bounds = CGRect(x: 0, y: 0, width: 0, height: 40)

        let viewModeHeaderViewModel = viewModel.viewModeHeaderViewModel
        let headerContentView = ResultsHeaderView {
            SortHeaderViewWrapper(config: sortHeaderConfig, sortOrder: currentSortOrder.toUIComponentSortOrderEntity()) { [weak self] order in
                self?.currentSortOrder = order.toDomainSortOrderEntity()
            }
            .simultaneousGesture(TapGesture().onEnded { [weak self] _ in
                guard let self else { return }
                viewModel.dispatch(.onSortHeaderViewPressed)
            })
        } rightView: {
            SearchResultsHeaderViewModeView(viewModel: viewModeHeaderViewModel)
        }

        let hostingViewController = UIHostingController(rootView: headerContentView)
        headerView.wrap(hostingViewController.view)
        controller.addChild(hostingViewController)
        controller.headerContainerView = headerView
        hostingViewController.view.backgroundColor = TokenColors.Background.page
        return headerView
    }

    @objc func updateViewModelViewModeToList() {
        viewModel.dispatch(.updateViewMode(.list))
    }

    @objc func updateViewModelViewModeToThumbnail() {
        viewModel.dispatch(.updateViewMode(.thumbnail))
    }

    private func triggerEvent(for sortOrder: MEGADomain.SortOrderEntity) {
        let eventIdentifier: (any EventIdentifier)? =  switch sortOrder {
        case .defaultAsc, .defaultDesc: SortByNameMenuItemEvent()
        case .sizeAsc, .sizeDesc: SortBySizeMenuItemEvent()
        case .modificationAsc, .modificationDesc: SortByDateModifiedMenuItemEvent()
        case .labelAsc, .labelDesc: SortByLabelMenuItemEvent()
        case .favouriteAsc, .favouriteDesc: SortByFavouriteMenuItemEvent()
        default: nil
        }
        guard let eventIdentifier else { return }
        DIContainer.tracker.trackAnalyticsEvent(with: eventIdentifier)
    }
}
