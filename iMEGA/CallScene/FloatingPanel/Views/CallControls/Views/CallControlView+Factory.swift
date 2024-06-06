import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import SwiftUI

extension CallControlView.Config {
    fileprivate static func backgroundEnabledColor() -> Color {
        isDesignTokenEnabled ? TokenColors.Button.secondary.swiftUI : Color(.gray474747)
    }
    
    fileprivate static func backgroundDisabledColor() -> Color {
        isDesignTokenEnabled ? TokenColors.Button.primary.swiftUI : Color(.whiteFFFFFF)
    }
    
    fileprivate static func endCallBackgroundColor() -> Color {
        isDesignTokenEnabled ? TokenColors.Components.interactive.swiftUI : Color(.redFF453A)
    }
    
    fileprivate static var isDesignTokenEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
    }
    
    static func microphone(enabled: Bool, action: @escaping () async -> Void) -> Self {
        .init(
            title: Strings.Localizable.Chat.Call.QuickAction.mic,
            icon: enabled ? Image(.callControlMicEnabled) : Image(.callControlMicDisabled),
            colors: .init(
                background: enabled ? backgroundEnabledColor() : backgroundDisabledColor(),
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
                background: enabled ? backgroundEnabledColor() : backgroundDisabledColor(),
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
                background: enabled ? backgroundEnabledColor() : backgroundDisabledColor(),
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
                background: backgroundEnabledColor(),
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
                background: endCallBackgroundColor(),
                foreground: TokenColors.Text.primary.swiftUI
            ),
            action: action
        )
    }
}
