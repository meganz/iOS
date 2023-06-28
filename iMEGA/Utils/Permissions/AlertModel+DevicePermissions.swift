extension AlertModel {
    static var audioMessage: String {
        NSLocalizedString("microphonePermissions",
                          comment: "Alert message to remember that MEGA app needs permission to use the Microphone to make calls and record videos and it doesn't have it")
    }
    static func audio(
        incomingCall: Bool,
        completion: @escaping () -> Void
    ) -> AlertModel {
        model(
            with: incomingCall ? NSLocalizedString("Incoming call", comment: "") : NSLocalizedString("attention", comment: "Alert title to attract attention"),
            message: audioMessage,
            completion: completion
        )
    }
    static func photo(completion: @escaping () -> Void) -> AlertModel {
        model(
            message: NSLocalizedString("photoLibraryPermissions", comment: "Alert message to explain that the MEGA app needs permission to access your device photos"),
            completion: completion
        )
    }
    static func video(completion: @escaping () -> Void) -> AlertModel {
        model(
            message: NSLocalizedString("cameraPermissions", comment: "Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it"),
            completion: completion
        )
    }
    static func model(
        with title: String = NSLocalizedString("attention", comment: "Alert title to attract attention"),
        message: String,
        completion: @escaping () -> Void
    ) -> AlertModel {
        .init(
            title: title,
            message: message,
            actions: [
                .init(title: NSLocalizedString("notNow", comment: ""), style: .cancel, handler: {}),
                .init(title: NSLocalizedString("settingsTitle", comment: "Title of the Settings section"), style: .default, handler: {
                    completion()
                })
            ]
        )
    }
}
