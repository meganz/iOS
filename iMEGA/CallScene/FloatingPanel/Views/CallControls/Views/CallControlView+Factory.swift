import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import SwiftUI

extension CallControlView.Config {
    
    static func microphone(enabled: Bool, action: @escaping () async -> Void) -> Self {
        .init(
            title: Strings.Localizable.Chat.Call.QuickAction.mic,
            icon: enabled ? Image(.callControlMicEnabled) : Image(.callControlMicDisabled),
            colors: .init(
                background: enabled ? TokenColors.Button.secondary.swiftUI : TokenColors.Button.primary.swiftUI,
                foreground: TokenColors.Text.primary.swiftUI
            ),
            action: action
        )
    }
    
    static func camera(enabled: Bool, action: @escaping () async -> Void) -> Self {
        .init(
            title: Strings.Localizable.Chat.Call.QuickAction.camera,
            icon: enabled ? Image(.callControlCameraEnabled) : Image(.callControlCameraDisabled),
            colors: .init(
                background: enabled ? TokenColors.Button.secondary.swiftUI : TokenColors.Button.primary.swiftUI,
                foreground: TokenColors.Text.primary.swiftUI
            ),
            action: action
        )
    }
    
    static func speaker(enabled: Bool, action: @escaping () async -> Void) -> Self {
        .init(
            title: Strings.Localizable.Meetings.QuickAction.speaker,
            icon: enabled ? Image(.callControlSpeakerEnabled) : Image(.callControlSpeakerDisabled),
            colors: .init(
                background: enabled ? TokenColors.Button.secondary.swiftUI : TokenColors.Button.primary.swiftUI,
                foreground: TokenColors.Text.primary.swiftUI
            ),
            action: action
        )
    }
    
    static func switchCamera(enabled: Bool, action: @escaping () async -> Void) -> Self {
        .init(
            title: Strings.Localizable.Meetings.QuickAction.flip,
            icon: enabled ? Image(.callControlSwitchCameraEnabled) : Image(.callControlSwitchCameraDisabled),
            colors: .init(
                background: TokenColors.Button.secondary.swiftUI,
                foreground: TokenColors.Text.primary.swiftUI
            ),
            action: action
        )
    }
    
    static func endCall(action: @escaping () async -> Void) -> Self {
        .init(
            title: Strings.Localizable.Chat.Call.QuickAction.endCall,
            icon: Image(.callControlEndCall),
            colors: .init(
                background: TokenColors.Components.interactive.swiftUI,
                foreground: TokenColors.Text.primary.swiftUI
            ),
            action: action
        )
    }
    
    static func moreButton(action: @escaping () async -> Void) -> Self {
        .init(
            title: Strings.Localizable.Chat.Call.QuickAction.more,
            icon: Image(.callContextMenu),
            colors: .init(
                background: TokenColors.Button.secondary.swiftUI,
                foreground: TokenColors.Text.primary.swiftUI
            ),
            action: action
        )
    }
}
