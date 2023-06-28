protocol PermissionAlertRouting {
    func audioPermission(
        modal: Bool,
        incomingCall: Bool,
        completion: @escaping (Bool) -> Void
    )
    
    func alertAudioPermission(incomingCall: Bool)
    
    func alertVideoPermission()
    
    func alertPhotosPermission()
    
    func presentModalNotificationsPermissionPrompt()
    
    func requestPermissionsFor(
        videoCall: Bool,
        granted: @escaping () -> Void
    )
}
