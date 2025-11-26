import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import Search
import SwiftUI

extension OfflineViewController {
    var sortOrder: MEGADomain.SortOrderEntity {
        get {
            Helper.sortType(for: currentOfflinePath).toSortOrderEntity()
        }
        set {
            Helper.save(newValue.toMEGASortOrderType(), for: currentOfflinePath)
            nodesSortTypeHasChanged()
        }
    }

    var sortHeaderCoordinator: SearchResultsSortHeaderCoordinator {
        .init(
            sortOptionsViewModel: .init(
                title: Strings.Localizable.sortTitle,
                sortOptions: SearchResultsSortOptionFactory.makeAll(
                    excludedKeys: [.favourite, .label, .dateAdded, .shareCreated, .linkCreated]
                )
            ),
            currentSortOrderProvider: { [weak self] in
                guard let self else { return .init(key: .name) }
                return sortOrder.toSearchSortOrderEntity()
            },
            sortOptionSelectionHandler: {  [weak self] in
                guard let self else { return }
                sortOrder = $0.sortOrder.toDomainSortOrderEntity()
            }
        )
    }

    @objc var shouldShowHeaderView: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp) && flavor != .HomeScreen
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

        let sortHeaderViewModel = viewModel.sortHeaderViewModel
        let viewModeHeaderViewModel = viewModel.viewModeHeaderViewModel

        let headerContentView = SearchResultsHeaderView {
            SearchResultsHeaderSortView(viewModel: sortHeaderViewModel)
        } rightView: {
            SearchResultsHeaderViewModeView(viewModel: viewModeHeaderViewModel)
        }

        let hostingController = UIHostingController(rootView: headerContentView)
        headerView.wrap(hostingController.view)
        controller.addChild(hostingController)
        controller.headerContainerView = headerView
        
        return headerView
    }
}
