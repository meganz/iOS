import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import UIKit

public protocol ExpiredAccountAlertPresenting {
    func presentAccountExpiredAlertIfNeeded()
}

@MainActor
public final class NodeTagsCellController: NSObject {
    private static let reuseIdentifier = "NodeTagsCellID"

    // A weak reference to the parent UIViewController that contains the table view.
    // The controller is responsible for managing the user interface or navigating when a row is selected.
    private weak var controller: UIViewController?
    private let viewModel: NodeTagsCellControllerModel
    private let expiredAccountAlertPresenter: (any ExpiredAccountAlertPresenting)?

    public init(
        controller: UIViewController,
        viewModel: NodeTagsCellControllerModel,
        expiredAccountAlertPresenter: (some ExpiredAccountAlertPresenting)?
    ) {
        self.controller = controller
        self.viewModel = viewModel
        self.expiredAccountAlertPresenter = expiredAccountAlertPresenter
        super.init()
    }

    public static func registerCell(for tableView: UITableView) {
        tableView.register(
            HostingTableViewCell<NodeTagsCellView>.self,
            forCellReuseIdentifier: Self.reuseIdentifier
        )
    }
}

extension NodeTagsCellController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.reuseIdentifier,
            for: indexPath
        ) as? HostingTableViewCell<NodeTagsCellView>

        guard let cell, let controller else { return HostingTableViewCell<NodeTagsCellView>() }

        let view = NodeTagsCellView(viewModel: self.viewModel.cellViewModel)
        cell.host(view, parent: controller)
        cell.backgroundColor = TokenColors.Background.page
        return cell
    }
}

extension NodeTagsCellController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller else { return }
        if viewModel.isExpiredBusinessOrProFlexiAccount {
            showFeatureUnavailabilityAlert()
        } else {
            let addTagsRouter = AddTagsViewRouter(nodeEntity: viewModel.node, presenter: controller)
            addTagsRouter.start()
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        NodeInfoCellHeaderView(title: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.header, topPadding: 10).toUIView()
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }
}

private extension NodeTagsCellController {
    func showFeatureUnavailabilityAlert() {
        expiredAccountAlertPresenter?.presentAccountExpiredAlertIfNeeded()
    }
}
