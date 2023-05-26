import Foundation

public enum CMOptions {
    case displayInline
}

/// Define a group of CMElements. A CMEntity may be composed of more CMEntities or/and actions. It helps us to define grouped Menus for iOS 14+.
///
///  - Parameters:
///     - displayInline: An option indicating the entity children is displayed inline with its parent entity instead of displaying as a submenu.
///     - currentChatStatus: Chat status obtained at the time the menu is created.
///     - currentSortType: Sorting type for the current context. It will be different depending on where the current menu is displayed.
///     - currentFilterType: Filter type for the current context. It will be different depending on where the current menu is displayed.
///     - dndRemainingTime: If DND is activated, it will contain the remaining time in the indicated language.
///     - children: List of CMElements that compone the entity. Each CMElement can be CMActionEntity representing an action or another CMEntity representing a Menu.
///
public final class CMEntity: CMElement {
    public var displayInline: Bool
    public var children: [CMElement]
    public var currentChatStatus: ChatStatusEntity?
    public var currentSortType: SortOrderEntity?
    public var currentFilterType: FilterEntity?
    public var dndRemainingTime: String?
    
    public init(type: CMElementTypeEntity = .unknown,
                displayInline: Bool = false,
                currentChatStatus: ChatStatusEntity? = nil,
                currentSortType: SortOrderEntity? = nil,
                currentFilterType: FilterEntity? = nil,
                dndRemainingTime: String? = nil,
                children: [CMElement]) {
        self.displayInline = displayInline
        self.currentChatStatus = currentChatStatus
        self.currentSortType = currentSortType
        self.currentFilterType = currentFilterType
        self.dndRemainingTime = dndRemainingTime
        self.children = children
        super.init(type: type)
    }
}

/// Define an action inside a CMEntity.
///
///  - Parameters:
///     - isEnabled: Define the action style depending on if is enabled (default value) or not (adopting the hidden style).
///     - state: Define the state of an action, on/off to represent the ✅, in case it's a selected action.
///
public final class CMActionEntity: CMElement {
    public var state: CMActionState
    public var isEnabled: Bool
    
    public init(type: CMElementTypeEntity = .unknown,
                isEnabled: Bool = true,
                state: CMActionState = .off) {
        self.isEnabled = isEnabled
        self.state = state
        super.init(type: type)
    }
}

public enum CMActionState {
    case on, off
}

/// Define the base class of any CMActionEntity or CMEntity. it contains all shared parameters.
///
///  - Parameters:
///     - identifier: Define the element identifier. It's very important to filter the actions or menus when they are tapped by the user and thus execute the corresponding delegate.
///
public class CMElement {
    public let type: CMElementTypeEntity
    
    public init(type: CMElementTypeEntity = .unknown) {
        self.type = type
    }
}
