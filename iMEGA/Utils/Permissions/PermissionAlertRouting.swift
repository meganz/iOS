@MainActor
protocol PermissionAlertRouting {
    func audioPermission(
        modal: Bool,
        incomingCall: Bool,
        completion: @Sendable @MainActor @escaping (Bool) -> Void
    )
    
    func alertAudioPermission(incomingCall: Bool)
    
    func alertVideoPermission()
    
    func alertPhotosPermission()
    
    func presentModalNotificationsPermissionPrompt()
    
    func requestPermissionsFor(
        videoCall: Bool,
        granted: @MainActor @escaping () -> Void
    )
}
