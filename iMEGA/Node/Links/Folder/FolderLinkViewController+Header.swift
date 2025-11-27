import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import Search
import SwiftUI

extension FolderLinkViewController {
    private var currentSortOrder: MEGADomain.SortOrderEntity {
        get {
            Helper.sortType(for: parentNode).toSortOrderEntity()
        }
        set {
            Helper.save(newValue.toMEGASortOrderType(), for: parentNode)
            reloadUI()
        }
    }

    var sortHeaderCoordinator: SearchResultsSortHeaderCoordinator {
        .init(
            sortOptionsViewModel: .init(
                title: Strings.Localizable.sortTitle,
                sortOptions: SearchResultsSortOptionFactory.makeAll(
                    excludedKeys: [.dateAdded, .shareCreated, .linkCreated]
                )
            ),
            currentSortOrderProvider: { [weak self] in
                guard let self else { return .init(key: .name) }
                return currentSortOrder.toSearchSortOrderEntity()
            },
            sortOptionSelectionHandler: { [weak self] in
                guard let self else { return }
                currentSortOrder = $0.sortOrder.toDomainSortOrderEntity()
            }
        )
    }

    var shouldShowHeaderView: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp)
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

        let sortHeaderViewModel = viewModel.sortHeaderViewModel
        let headerContentView = SearchResultsHeaderView(leftView: {
            SearchResultsHeaderSortView(viewModel: sortHeaderViewModel)
        })

        let hostingViewController = UIHostingController(rootView: headerContentView)
        headerView.wrap(hostingViewController.view)
        controller.addChild(hostingViewController)
        controller.headerContainerView = hostingViewController.view
        return headerView
    }
}
