import UIKit

@MainActor
struct MediaBottomToolbarItemsFactory {

    weak var actionDelegate: (any MediaToolbarActionDelegate)?

    // MARK: - Build Methods

    func buildToolbarItems(
        config: MediaBottomToolbarConfig
    ) -> [UIBarButtonItem] {
        return config.actions.map { buildBarButtonItem(for: $0, config: config) }
    }

    // MARK: - Private Methods

    private func buildBarButtonItem(
        for action: MediaBottomToolbarAction,
        config: MediaBottomToolbarConfig
    ) -> UIBarButtonItem {
        let item = UIBarButtonItem(image: action.image)

        item.primaryAction = UIAction(
            image: action.image,
            handler: { [weak actionDelegate] _ in
                actionDelegate?.handleToolbarAction(action)
            }
        )

        item.isEnabled = barButtonEnabled(for: action, config: config)

        return item
    }

    private func barButtonEnabled(
        for action: MediaBottomToolbarAction,
        config: MediaBottomToolbarConfig
    ) -> Bool {
        guard config.hasSelection else {
            return false
        }

        return switch action {
        case .removeLink:
            config.isAllExported
        default:
            true
        }
    }
}

// MARK: - Action Delegate Protocol

@MainActor
protocol MediaToolbarActionDelegate: AnyObject {
    func handleToolbarAction(_ action: MediaBottomToolbarAction)
}
