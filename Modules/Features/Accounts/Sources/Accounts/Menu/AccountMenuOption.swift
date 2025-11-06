import MEGADesignToken
import SwiftUI

struct AccountMenuOption: Identifiable {
    enum AccountMenuRowType {
        case disclosure(action: () -> Void)
        case externalLink(action: () -> Void)
        case withButton(title: String, action: () -> Void)
    }
    
    struct IconConfiguration {
        enum IconStyle {
            case normal
            case rounded
        }

        let icon: Image
        let style: IconStyle
        let backgroundColor: Color

        init(icon: Image, style: IconStyle = .normal, backgroundColor: Color = TokenColors.Icon.primary.swiftUI) {
            self.icon = icon
            self.style = style
            self.backgroundColor = backgroundColor
        }
    }

    enum TextLoadState {
        case none
        case loading
        case value(String)
    }

    let id: UUID = UUID()
    let iconConfiguration: IconConfiguration
    let title: String
    let subtitleState: TextLoadState
    let notificationCount: Int?
    let rowType: AccountMenuRowType

    init(
        iconConfiguration: IconConfiguration,
        title: String,
        subtitleState: TextLoadState = nil,
        notificationCount: Int? = nil,
        rowType: AccountMenuRowType,
    ) {
        self.iconConfiguration = iconConfiguration
        self.title = title
        self.subtitleState = subtitleState
        self.notificationCount = notificationCount
        self.rowType = rowType
    }
}

extension AccountMenuOption.TextLoadState: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .none
    }
}
