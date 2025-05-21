import MEGAAssets
import MEGAL10n
import SwiftUI

enum ChatRoomParticipantPrivilege: String, CaseIterable {
    case unknown
    case removed
    case readOnly
    case standard
    case moderator
    
    var localizedTitle: String {
        switch self {
        case .unknown, .removed, .readOnly:
            return Strings.Localizable.readOnly
        case .standard:
            return Strings.Localizable.standard
        case .moderator:
            return Strings.Localizable.moderator
        }
    }
    
    var image: Image {
        switch self {
        case .unknown, .removed, .readOnly:
            return MEGAAssets.Image.readOnlyChat
        case .standard:
            return MEGAAssets.Image.standard
        case .moderator:
            return MEGAAssets.Image.moderator
        }
    }
}
