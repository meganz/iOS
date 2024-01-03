import MEGADesignToken
import MEGAPresentation
import SwiftUI
import UIKit

extension MEGAAppColor {
    enum Chat {
        case chatListArchiveSwipeActionBackground
        case chatListMoreSwipeActionBackground
        case chatListSectionTitle
        case chatListSubtitleText
        case chatListSectionBackground
        case chatListMeetingTimeText
        case chatListSectionBottomDividerBackground
        case chatReactionBubbleBorder
        case chatReactionBubbleSelectedDark
        case chatReactionBubbleSelectedLight
        case chatReactionBubbleUnselectedDefault
        case chatMeetingFrequencySelectionTickMark
        case chatAvatarBackground
        case chatTabSelectedText
        case chatTabNormalText
        case chatTabSelectedBackground
        case chatTabNormalBackground
        case chatStatusOnline
        case chatStatusOffline
        case chatStatusAway
        case chatStatusBusy
        case callAvatarBackground
        case callAvatarBackgroundGradient
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .chatListArchiveSwipeActionBackground:
                TokenColors.Background.blur
            case .chatListMoreSwipeActionBackground:
                TokenColors.Background.blur
            case .chatListSectionTitle:
                TokenColors.Background.blur
            case .chatListSubtitleText:
                TokenColors.Background.blur
            case .chatListSectionBackground:
                TokenColors.Background.blur
            case .chatListMeetingTimeText:
                TokenColors.Background.blur
            case .chatListSectionBottomDividerBackground:
                TokenColors.Background.blur
            case .chatReactionBubbleBorder:
                TokenColors.Background.blur
            case .chatReactionBubbleSelectedDark:
                TokenColors.Background.blur
            case .chatReactionBubbleSelectedLight:
                TokenColors.Background.blur
            case .chatReactionBubbleUnselectedDefault:
                TokenColors.Background.blur
            case .chatMeetingFrequencySelectionTickMark:
                TokenColors.Background.blur
            case .chatAvatarBackground:
                TokenColors.Background.blur
            case .chatTabSelectedText: 
                TokenColors.Text.primary
            case .chatTabNormalText:
                TokenColors.Text.primary
            case .chatTabSelectedBackground:
                TokenColors.Background.blur
            case .chatTabNormalBackground: 
                TokenColors.Background.blur
            case .chatStatusOnline:
                TokenColors.Text.primary
            case .chatStatusOffline:
                TokenColors.Text.primary
            case .chatStatusAway: 
                TokenColors.Text.primary
            case .chatStatusBusy: 
                TokenColors.Text.primary
            case .callAvatarBackground: 
                TokenColors.Background.blur
            case .callAvatarBackgroundGradient:
                TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .chatListArchiveSwipeActionBackground: 
                UIColor.chatListArchiveSwipeActionBackground
            case .chatListMoreSwipeActionBackground:
                UIColor.chatListMoreSwipeActionBackground
            case .chatListSectionTitle:
                UIColor.chatListSectionTitle
            case .chatListSubtitleText:
                UIColor.chatListSubtitleText
            case .chatListSectionBackground:
                UIColor.chatListSectionBackground
            case .chatListMeetingTimeText:
                UIColor.chatListMeetingTimeText
            case .chatListSectionBottomDividerBackground:
                UIColor.chatListSectionBottomDividerBackground
            case .chatReactionBubbleBorder:
                UIColor.chatReactionBubbleBorder
            case .chatReactionBubbleSelectedDark:
                UIColor.chatReactionBubbleSelectedDark
            case .chatReactionBubbleSelectedLight:
                UIColor.chatReactionBubbleSelectedLight
            case .chatReactionBubbleUnselectedDefault:
                UIColor.chatReactionBubbleUnselectedDefault
            case .chatMeetingFrequencySelectionTickMark:
                UIColor.chatMeetingFrequencySelectionTickMark
            case .chatAvatarBackground:
                UIColor.chatAvatarBackground
            case .chatTabSelectedText:
                UIColor.chatTabSelectedText
            case .chatTabNormalText:
                UIColor.chatTabNormalText
            case .chatTabSelectedBackground: 
                UIColor.chatTabSelectedBackground
            case .chatTabNormalBackground:
                UIColor.chatTabNormalBackground
            case .chatStatusOnline:
                UIColor.chatStatusOnline
            case .chatStatusOffline: 
                UIColor.chatStatusOffline
            case .chatStatusAway: 
                UIColor.chatStatusAway
            case .chatStatusBusy: 
                UIColor.chatStatusBusy
            case .callAvatarBackground:
                UIColor.callAvatarBackground
            case .callAvatarBackgroundGradient: 
                UIColor.callAvatarBackgroundGradient
            }
        }
    }
}
