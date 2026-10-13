import Foundation
import MEGADomain

public enum HomeWidgetRouteType {
    case shortcut(ShortcutType)
    case accountUpgrade
    case promotionalBanner(_ url: URL)
    case viewedLink(_ url: URL)
    case promoLandingDialog
    case offline
    case transfers
    case cameraUploadsOnboarding
    case cameraUploadsSettings
    case overDiskQuota
    case album(AlbumEntity)
    case inviteContacts
    case scheduleMeeting
}
