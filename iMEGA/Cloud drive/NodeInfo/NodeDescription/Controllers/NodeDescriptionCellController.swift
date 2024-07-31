import MEGASwift
import MEGASwiftUI
import SwiftUI

final class NodeDescriptionCellController: NSObject {
    private static let reuseIdentifier = "NodeDescriptionNonEditableView"
    private let viewModel: NodeDescriptionViewModel
    private weak var controller: UIViewController?

    init(viewModel: NodeDescriptionViewModel, controller: UIViewController) {
        self.viewModel = viewModel
        self.controller = controller
    }

    static func registerCell(for tableView: UITableView) {
        tableView.register(
            HostingTableViewCell<NodeDescriptionNonEditableView>.self,
            forCellReuseIdentifier: NodeDescriptionCellController.reuseIdentifier
        )
    }
}

extension NodeDescriptionCellController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.reuseIdentifier,
            for: indexPath
        ) as? HostingTableViewCell<NodeDescriptionNonEditableView>

        guard let cell, let controller else { return HostingTableViewCell<NodeDescriptionNonEditableView>() }
        
        let verticalPadding: CGFloat? = if #available(iOS 16.0, *) { nil } else { 11 }
        let view = NodeDescriptionNonEditableView(
            description: viewModel.description,
            verticalPadding: verticalPadding
        )
        cell.host(view, parent: controller)

        return cell
    }
}

extension NodeDescriptionCellController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        NodeDescriptionHeaderView(title: viewModel.header).toUIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = viewModel.footer else { return nil }
        return NodeDescriptionFooterView(leadingText: footer, trailingText: nil).toUIView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
}
