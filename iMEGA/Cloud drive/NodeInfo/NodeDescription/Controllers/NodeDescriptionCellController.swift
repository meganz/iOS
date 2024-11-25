import CloudDrive
import Combine
import MEGADesignToken
import MEGADomain
import MEGASwift
import MEGASwiftUI
import MEGAUIKit
import SwiftUI

@MainActor
final class NodeDescriptionCellController: NSObject {
    private var keyboardShownSubscription: AnyCancellable?
    let viewModel: NodeDescriptionCellControllerModel

    init(viewModel: NodeDescriptionCellControllerModel) {
        self.viewModel = viewModel
        super.init()
    }

    static func registerCell(for tableView: UITableView) {
        tableView.register(
            NodeDescriptionViewCell.self,
            forCellReuseIdentifier: NodeDescriptionViewCell.reuseIdentifier
        )
    }

    func addKeyboardNotifications(tableView: UITableView, indexPath: IndexPath) {
        guard keyboardShownSubscription == nil else { return }

        keyboardShownSubscription = NotificationCenter
            .default
            .publisher(for: UIResponder.keyboardDidShowNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                scrollToBottomIfNeeded(tableView: tableView, indexPath: indexPath)
            }
    }

    func removeKeyboardNotifications() {
        keyboardShownSubscription?.cancel()
        keyboardShownSubscription = nil
    }
    
    func processNodeUpdate(_ updatedNode: NodeEntity) {
        viewModel.updateDescription(with: updatedNode)
    }

    private func scrollToBottomIfNeeded(tableView: UITableView, indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath),
              cell.containsFirstResponder() else {
            return
        }

        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)

        // scrollToRow does not consider the footer. So need add the height of the footer to content offset
        let footerRect = tableView.rectForFooter(inSection: indexPath.section)
        var contentOffset = tableView.contentOffset
        contentOffset.y += footerRect.height
        tableView.setContentOffset(contentOffset, animated: false)
    }
}

extension NodeDescriptionCellController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NodeDescriptionViewCell.reuseIdentifier,
            for: indexPath
        ) as? NodeDescriptionViewCell else {
            return UITableViewCell()
        }
        viewModel.scrollToCell = { [weak self, weak tableView] in
            guard let self, let tableView else { return }
            scrollToBottomIfNeeded(tableView: tableView, indexPath: indexPath)
        }
        addKeyboardNotifications(tableView: tableView, indexPath: indexPath)
        cell.viewModel = viewModel.cellViewModel
        return cell
    }
}

extension NodeDescriptionCellController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        NodeInfoCellHeaderView(title: viewModel.header).toUIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        NodeDescriptionFooterView(viewModel: self.viewModel.footerViewModel).toUIView()
    }
}
