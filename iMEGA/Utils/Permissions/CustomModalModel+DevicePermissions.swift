import MEGAAssets
import MEGAL10n

extension CustomModalModel {
    static func notifications(completion: @escaping (Dismisser) -> Void) -> Self {
        .init(
            image: MEGAAssets.UIImage.notificationDevicePermission,
            viewTitle: Strings.localized("Enable Notifications", comment: "Title label that explains that the user is going to be asked for the notifications permission"),
            details: Strings.localized("We would like to send you notifications so you receive new messages on your device instantly.", comment: "Detailed explanation of why the user should give permission to deliver notifications"),
            firstButtonTitle: Strings.localized("continue", comment: "'Next' button in a dialog"),
            dismissButtonTitle: nil,
            firstCompletion: completion
        )
    }
    
    static func audioCall(
        incomingCall: Bool,
        completion: @escaping (Dismisser) -> Void
    ) -> Self {
        .init(
            image: MEGAAssets.UIImage.groupChat,
            viewTitle: incomingCall ? Strings.localized("Incoming call", comment: "") : Strings.localized("Enable Microphone and Camera", comment: "Title label that explains that the user is going to be asked for the microphone and camera permission"),
            details: Strings.localized("To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone", comment: "Detailed explanation of why the user should give permission to access to the camera and the microphone"),
            firstButtonTitle: Strings.localized("Allow Access", comment: "Button which triggers a request for a specific permission, that have been explained to the user beforehand"),
            dismissButtonTitle: Strings.localized("notNow", comment: ""),
            firstCompletion: completion
        )
    }
}
