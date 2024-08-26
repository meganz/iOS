import Combine
import MEGADesignToken
import MEGASwift
import MEGASwiftUI
import SwiftUI

final class NodeDescriptionCellController: NSObject {
    private static let reuseIdentifier = "NodeDescriptionCellID"
    private let maxCharactersAllowed = 300
    private let viewModel: NodeDescriptionViewModel
    private var keyboardSubscriptions: NodeDescriptionKeyboardSubscriptions?
    private var subscriptions = Set<AnyCancellable>()
    private lazy var footerViewModel = NodeDescriptionFooterViewModel(
        leadingText: viewModel.footer,
        description: viewModel.description.isPlaceholder ? nil : viewModel.description.text,
        maxCharactersAllowed: maxCharactersAllowed
    )

    init(viewModel: NodeDescriptionViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    static func registerCell(for tableView: UITableView) {
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: NodeDescriptionCellController.reuseIdentifier
        )
    }

    func addKeyboardNotifications(tableView: UITableView, indexPath: IndexPath) {
        guard keyboardSubscriptions == nil else { return }

        let keyboardSubscriptions = NodeDescriptionKeyboardSubscriptions()
        self.keyboardSubscriptions = keyboardSubscriptions

        keyboardSubscriptions
            .publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak tableView] keyboardState in
                guard let self,
                      let tableView else {
                    return
                }
                updateUI(for: keyboardState, tableView: tableView, indexPath: indexPath)
            }
            .store(in: &subscriptions)
    }

    func removeKeyboardNotifications() {
        subscriptions.forEach { $0.cancel() }
        subscriptions = []
        keyboardSubscriptions = nil
    }

    private func scrollToBottom(tableView: UITableView, indexPath: IndexPath) {
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)

        // scrollToRow does not consider the footer. So need add the height of the footer to content offset
        let footerRect = tableView.rectForFooter(inSection: indexPath.section)
        var contentOffset = tableView.contentOffset
        contentOffset.y += footerRect.height
        tableView.setContentOffset(contentOffset, animated: false)
    }

    private func cellBackground(traitCollection: UITraitCollection) -> UIColor {
        UIColor.isDesignTokenEnabled()
        ? TokenColors.Background.page
        : traitCollection.userInterfaceStyle == .dark
        ? UIColor.black2C2C2E
        : UIColor.whiteFFFFFF
    }

    private func updateUI(
        for keyboardState: NodeDescriptionKeyboardSubscriptions.KeyboardSubscription,
        tableView: UITableView,
        indexPath: IndexPath
    ) {
        UIView.performWithoutAnimation { [weak self] in
            guard let self else { return }
            tableView.beginUpdates()

            if keyboardState == .didShow {
                footerViewModel.description = footerViewModel.description
                ?? (viewModel.description.isPlaceholder ? "" : viewModel.description.text)
                footerViewModel.showTrailingText()
            } else {
                footerViewModel.trailingText = nil
            }

            tableView.endUpdates()

            if keyboardState == .didShow,
               let cell = tableView.cellForRow(at: indexPath),
               cell.containsFirstResponder() {
                scrollToBottom(tableView: tableView, indexPath: indexPath)
            }
        }
    }
}

extension NodeDescriptionCellController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.reuseIdentifier, for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = cellBackground(traitCollection: tableView.traitCollection)
        addKeyboardNotifications(tableView: tableView, indexPath: indexPath)
        cell.contentConfiguration = makeContentConfiguration(tableView: tableView, cellForRowAt: indexPath)
        return cell
    }

    private func makeContentConfiguration(
        tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> NodeDescriptionContentConfiguration {
        NodeDescriptionContentConfiguration(
            description: viewModel.description,
            editingDisabled: viewModel.hasReadOnlyAccess,
            maxCharactersAllowed: maxCharactersAllowed
        ) { [weak self, weak tableView] text in
            guard let self, let tableView else { return }
            update(footerText: text, andScrollTo: indexPath, tableView: tableView)
        } saveDescription: { updatedDescription in
            MEGALogDebug("Updated description is \(updatedDescription)")
            // SAO-1730: Save node description
        } updatedLayout: { [weak self, weak tableView] updates in
            guard let self, let tableView else { return }
            updateAndScroll(to: indexPath, tableView: tableView, updates: updates)
        }
    }

    private func update(footerText: String, andScrollTo indexPath: IndexPath, tableView: UITableView) {
        updateAndScroll(to: indexPath, tableView: tableView) { [weak self] in
            guard let self else { return }
            footerViewModel.description = footerText
            footerViewModel.showTrailingText()
        }
    }

    private func updateAndScroll(to indexPath: IndexPath, tableView: UITableView, updates: () -> Void) {
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            updates()
            tableView.endUpdates()
        }

        guard footerViewModel.trailingText != nil else { return }
        scrollToBottom(tableView: tableView, indexPath: indexPath)
    }
}

extension NodeDescriptionCellController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        NodeDescriptionHeaderView(title: viewModel.header).toUIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        NodeDescriptionFooterView(viewModel: self.footerViewModel).toUIView()
    }
}
