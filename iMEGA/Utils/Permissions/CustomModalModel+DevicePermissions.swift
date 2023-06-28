extension CustomModalModel {
    static func notifications(completion: @escaping (Dismisser) -> Void) -> Self {
        .init(
            image: UIImage(named: "notificationDevicePermission")!,
            viewTitle: NSLocalizedString("Enable Notifications", comment: "Title label that explains that the user is going to be asked for the notifications permission"),
            details: NSLocalizedString("We would like to send you notifications so you receive new messages on your device instantly.", comment: "Detailed explanation of why the user should give permission to deliver notifications"),
            firstButtonTitle: NSLocalizedString("continue", comment: "'Next' button in a dialog"),
            dismissButtonTitle: nil,
            firstCompletion: completion
        )
    }
    
    static func audioCall(
        incomingCall: Bool,
        completion: @escaping (Dismisser) -> Void
    ) -> Self {
        .init(
            image: UIImage(named: "groupChat")!,
            viewTitle: incomingCall ? NSLocalizedString("Incoming call", comment: "") : NSLocalizedString("Enable Microphone and Camera", comment: "Title label that explains that the user is going to be asked for the microphone and camera permission"),
            details: NSLocalizedString("To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone", comment: "Detailed explanation of why the user should give permission to access to the camera and the microphone"),
            firstButtonTitle: NSLocalizedString("Allow Access", comment: "Button which triggers a request for a specific permission, that have been explained to the user beforehand"),
            dismissButtonTitle: NSLocalizedString("notNow", comment: ""),
            firstCompletion: completion
        )
    }
}
