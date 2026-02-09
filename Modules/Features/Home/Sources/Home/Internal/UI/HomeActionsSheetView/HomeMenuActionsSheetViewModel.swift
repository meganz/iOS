import SwiftUI

public struct HomeMenuAction: Sendable, Identifiable {
    public var id: String { title }
    let image: Image
    let title: String
    let action: @MainActor () -> Void

    public init(
        image: Image,
        title: String,
        action: @escaping @MainActor () -> Void
    ) {
        self.image = image
        self.title = title
        self.action = action
    }
}

@MainActor
public class HomeMenuActionsSheetViewModel: Sendable {

    private var selectedAction: HomeMenuAction?
    var menuActions: [HomeMenuAction]

    public init(menuActions: [HomeMenuAction]) {
        self.menuActions = menuActions
    }

    func saveSelectedAction(_ action: HomeMenuAction) {
        selectedAction = action
    }

    func performSelectedActionAfterDismissal() {
        selectedAction?.action()
        selectedAction = nil
    }
}
