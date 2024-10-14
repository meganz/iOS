import Foundation
import MEGADomain
import MEGAL10n
import MEGASwiftUI

@MainActor
final class NodeTagsCellController: NSObject {
    private static let reuseIdentifier = "NodeTagsCellID"

    // A weak reference to the parent UIViewController that contains the table view.
    // The controller is responsible for managing the user interface or navigating when a row is selected.
    private weak var controller: UIViewController?

    private let accountUseCase: any AccountUseCaseProtocol

    init(controller: UIViewController, accountUseCase: some AccountUseCaseProtocol) {
        self.controller = controller
        self.accountUseCase = accountUseCase
    }

    static func registerCell(for tableView: UITableView) {
        tableView.register(
            HostingTableViewCell<NodeTagsCellView>.self,
            forCellReuseIdentifier: Self.reuseIdentifier
        )
    }
}

extension NodeTagsCellController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.reuseIdentifier,
            for: indexPath
        ) as? HostingTableViewCell<NodeTagsCellView>

        guard let cell, let controller else { return HostingTableViewCell<NodeTagsCellView>() }

        let view = NodeTagsCellView(viewModel: NodeTagsCellViewModel(accountUseCase: self.accountUseCase))
        cell.host(view, parent: controller)
        return cell
    }
}

extension NodeTagsCellController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller else { return }
        let addTagsRouter = AddTagsViewRouter(presenter: controller)
        addTagsRouter.start()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        NodeInfoCellHeaderView(title: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.header, topPadding: 10).toUIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }
}
