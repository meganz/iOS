import MEGADesignToken
import SwiftUI

struct ChatRoomsEmptyViewState {
    let topRows: [ChatRoomsTopRowViewState]
    let center: ChatRoomsEmptyCenterViewState
    let bottomButtons: [MenuButtonModel]
    
    func showDivider(for row: ChatRoomsTopRowViewState) -> Bool {
        let indexOfRow = topRows.firstIndex(where: { element in
            element.id == row.id
        })
        return indexOfRow != topRows.count - 1
    }
}

struct ChatRoomsEmptyCenterViewState {
    var image: ImageResource
    var title: String
    var titleBold: Bool = false
    var description: String?
    var linkTapped: (() -> Void)?
}

struct MenuButtonModel: Identifiable {
    
    func applying(theme: MenuButtonModel.Theme) -> Self {
        var _self = self
        _self.theme = theme
        return _self
    }
    
    init(
        theme: MenuButtonModel.Theme = .dark,
        title: String,
        interaction: MenuButtonModel.Interaction,
        isDesignTokenEnabled: Bool
    ) {
        self.theme = theme
        self.title = title
        self.interaction = interaction
        self.isDesignTokenEnabled = isDesignTokenEnabled
    }
    
    struct Menu: Identifiable {
        let name: String
        let image: ImageResource
        let action: () -> Void
        
        var id: String {
            name
        }
    }
    
    enum Theme {
        case dark // black background in OS light mode, light in OS dark mode
        case light // light background in OS light mode, dark in OS dark mode
    }
    
    // small configuration to be able to create MenuButtonModel that either
    // executes single action or shows menu, using a single piece of state
    enum Interaction {
        case action(() -> Void)
        case menu([Menu])
    }
    
    var theme: Theme = .dark
    var title: String
    var interaction: Interaction
    
    var backgroundColor: Color {
        isDesignTokenEnabled ? 
           tokenBackgroundColor :
           legacyBackgroundColor
    }
    
    private var legacyBackgroundColor: Color {
        theme == .dark ? Color(red: 0, green: 0.66, blue: 0.52) : Color(red: 0, green: 0.66, blue: 0.52)
    }
    
    private var tokenBackgroundColor: Color {
        theme == .dark ? TokenColors.Icon.accent.swiftUI : TokenColors.Support.success.swiftUI
    }
    
    var textColor: Color {
        isDesignTokenEnabled ? TokenColors.Text.inverseAccent.swiftUI : MEGAAppColor.White._FFFFFF.color }
    
    let isDesignTokenEnabled: Bool
    
    var id: String {
        title
    }
}
