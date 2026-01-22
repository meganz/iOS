import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import Search
import SwiftUI

extension OfflineViewController {
    var sortOrder: MEGADomain.SortOrderEntity {
        get {
            Helper.sortType(for: currentOfflinePath).toSortOrderEntity()
        }
        set {
            Helper.save(newValue.toMEGASortOrderType(), for: currentOfflinePath)
            triggerEvent(for: newValue)
            nodesSortTypeHasChanged()
        }
    }

    var sortHeaderConfig: SortHeaderConfig {
        let keys: [MEGAUIComponent.SortOrder.Key] = [
            .name, .lastModified, .size
        ]
        return SortHeaderConfig(
            title: Strings.Localizable.sortTitle,
            options: keys.sortOptions
        )
    }

    @objc var shouldShowHeaderView: Bool {
        DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosCloudDriveRevamp) && flavor != .HomeScreen
    }

    @objc func headerView(for controller: UIViewController) -> UIView {
        guard let viewController = controller as? (any OfflineHeaderViewHosting) else {
            assertionFailure("\(controller) should implement the OfflineHeaderViewProtocol protocol")
            return UIView()
        }

        guard let headerContainerView = viewController.headerContainerView else {
            return makeHeaderView(controller: viewController)
        }

        return headerContainerView
    }

    private func makeHeaderView(controller: some OfflineHeaderViewHosting) -> UIView {
        let headerView = UIView()
        headerView.bounds = CGRect(x: 0, y: 0, width: 0, height: 40)

        let viewModeHeaderViewModel = viewModel.viewModeHeaderViewModel

        let headerContentView = ResultsHeaderView {
            SortHeaderViewWrapper(config: sortHeaderConfig, sortOrder: sortOrder.toUIComponentSortOrderEntity()) { [weak self] order in
                self?.sortOrder = order.toDomainSortOrderEntity()
            }
            .simultaneousGesture(TapGesture().onEnded { [weak self] _ in
                guard let self else { return }
                viewModel.dispatch(.onSortHeaderViewPressed)
            })  
        } rightView: {
            SearchResultsHeaderViewModeView(viewModel: viewModeHeaderViewModel)
        }

        let hostingController = UIHostingController(rootView: headerContentView)
        headerView.wrap(hostingController.view)
        controller.addChild(hostingController)
        controller.headerContainerView = headerView
        hostingController.view.backgroundColor = TokenColors.Background.page

        return headerView
    }

    private func triggerEvent(for sortOrder: MEGADomain.SortOrderEntity) {
        let eventIdentifier: (any EventIdentifier)? =  switch sortOrder {
        case .defaultAsc, .defaultDesc: SortByNameMenuItemEvent()
        case .sizeAsc, .sizeDesc: SortBySizeMenuItemEvent()
        case .modificationAsc, .modificationDesc: SortByDateModifiedMenuItemEvent()
        default: nil
        }
        guard let eventIdentifier else { return }
        DIContainer.tracker.trackAnalyticsEvent(with: eventIdentifier)
    }
}
