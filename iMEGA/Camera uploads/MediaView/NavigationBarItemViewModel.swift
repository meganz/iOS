import MEGADomain
import SwiftUI

// MARK: - Navigation Bar Item Placement

enum NavigationBarItemPlacement {
    case leading
    case trailing

    var toolbarPlacement: ToolbarItemPlacement {
        switch self {
        case .leading:
            return .navigationBarLeading
        case .trailing:
            return .navigationBarTrailing
        }
    }
}

// MARK: - Navigation Bar Item Type

enum NavigationBarItemType {
    case cameraUploadStatus(viewModel: CameraUploadStatusButtonViewModel)
    case imageButton(image: UIImage, action: () -> Void)
    case textButton(text: String, action: () -> Void)
    case contextMenu(config: CMConfigEntity, manager: ContextMenuManager)
}

// MARK: - Navigation Bar Item ViewModel

struct NavigationBarItemViewModel: Identifiable, Equatable {
    /// Constant identifier to avoid unnecessary redraws when view models contain the same items
    let id: String

    let placement: NavigationBarItemPlacement

    let viewType: NavigationBarItemType

    init(
        id: String,
        placement: NavigationBarItemPlacement,
        type: NavigationBarItemType
    ) {
        self.id = id
        self.placement = placement
        self.viewType = type
    }

    // MARK: - Equatable

    static func == (lhs: NavigationBarItemViewModel, rhs: NavigationBarItemViewModel) -> Bool {
        lhs.id == rhs.id && lhs.placement == rhs.placement
    }
}
