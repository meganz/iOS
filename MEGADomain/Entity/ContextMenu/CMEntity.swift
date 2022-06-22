
enum CMOptions {
    case displayInline
}

/// Define a group of CMElements. A CMEntity may be composed of more CMEntities or/and actions. It helps us to define grouped Menus for iOS 14+.
///
///  - Parameters:
///     - displayInline: An option indicating the entity children is displayed inline with its parent entity instead of displaying as a submenu.
///     - children: List of CMElements that compone the entity. Each CMElement can be CMActionEntity representing an action or another CMEntity representing a Menu.
///
final class CMEntity: CMElement {
    var displayInline: Bool
    var children: [CMElement]
    
    init(title: String? = nil,
         detail: String? = nil,
         image: UIImage? = nil,
         identifier: String? = nil,
         displayInline: Bool = false,
         children: [CMElement]) {
        
        self.displayInline = displayInline
        self.children = children
        super.init(title: title, detail: detail, image: image, identifier: identifier)
    }
}

/// Define an action inside a CMEntity.
///
///  - Parameters:
///     - state: Define the state of an action, on/off to represent the ✅, in case it's a selected action.
///
final class CMActionEntity: CMElement {
    var state: ActionState
    
    init(title: String? = nil,
         detail: String? = nil,
         image: UIImage? = nil,
         identifier: String? = nil,
         state: ActionState = .off) {
        
        self.state = state
        super.init(title: title, detail: detail, image: image, identifier: identifier)
    }
}

enum ActionState {
    case on, off
}

/// Define the base class of any CMActionEntity or CMEntity. it contains all shared parameters.
///
///  - Parameters:
///     - title: Define the element title.
///     - detail: Define the element subtitle or detail text.
///     - image: Define the element icon.
///     - identifier: Define the element identifier. It's very important to filter the actions or menus when they are tapped by the user and thus execute the corresponding delegate.
///
class CMElement {
    let title: String?
    let detail: String?
    let image: UIImage?
    let identifier: String?
    
    init(title: String? = nil,
         detail: String? = nil,
         image: UIImage? = nil,
         identifier: String? = nil) {
        
        self.title = title
        self.detail = detail
        self.image = image
        self.identifier = identifier
    }
}
