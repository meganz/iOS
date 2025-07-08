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

    let id: UUID = UUID()
    let iconConfiguration: IconConfiguration
    let title: String
    let subtitle: String?
    let notificationCount: Int?
    let rowType: AccountMenuRowType

    init(
        iconConfiguration: IconConfiguration,
        title: String,
        subtitle: String? = nil,
        notificationCount: Int? = nil,
        rowType: AccountMenuRowType,
    ) {
        self.iconConfiguration = iconConfiguration
        self.title = title
        self.subtitle = subtitle
        self.notificationCount = notificationCount
        self.rowType = rowType
    }
}
