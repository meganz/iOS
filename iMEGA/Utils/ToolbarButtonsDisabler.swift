import MEGADomain
import UIKit

enum ToolbarButtonsDisabler {
    /// When selecting nodes, toolbar actions should be disabled if any of the selected nodes is disputed (taken down)
    /// - Parameters:
    ///   - toolbarButtons: Toolbar buttons we handle enablement for
    ///   - enabled: Flag indicating whether toolbar actions should be enabled or disabled by default
    ///   - selectedNodesArray: Currently selected nodes
    static func disableConditionally(
        toolbarButtons: [UIBarButtonItem?],
        enabled: Bool,
        selectedNodesArray: [NodeEntity]
    ) {
        let enableIfNotDisputed = !selectedNodesArray.contains(where: { $0.isTakenDown }) && enabled

        for button in toolbarButtons {
            button?.isEnabled = enableIfNotDisputed
        }
    }
}
