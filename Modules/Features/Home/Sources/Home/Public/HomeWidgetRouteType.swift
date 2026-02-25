import Foundation

public enum HomeWidgetRouteType {
    case shortcut(ShortcutType)
    case accountUpgrade
    case promotionalBanner(_ url: URL)
}
