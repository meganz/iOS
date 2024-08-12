// responsible for presenting UIAlerts and Custom Modals
// in situations related to device permissions such as
// audio/video/photos/notifications
import MEGAPermissions

struct PermissionAlertRouter {
    
    static func makeRouter(deviceHandler: some DevicePermissionsHandling) -> PermissionAlertRouter {
        .init(
            modalPresenter: {
                UIApplication.present($0)
            },
            settingsOpener: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            },
            notificationRegisterer: {
                UIApplication.shared.registerForRemoteNotifications()
            },
            deviceHandler: deviceHandler
        )
    }
    
    let modalPresenter: (PermissionsModalModel) -> Void
    let settingsOpener: () -> Void
    let notificationRegisterer: () -> Void
    let deviceHandler: any DevicePermissionsHandling
    
    private var openSettings: () -> Void {
        {
            settingsOpener()
        }
    }
    
    private func modalAudioPermissionForIncomingCall(
        incomingCall: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        let dismisserCompletion: (Dismisser) -> Void = { dismisser in
            dismisser()
            deviceHandler.requestAudioPermission { audioGranted in
                completion(audioGranted)
            }
        }
        modalPresenter(.custom(.audioCall(incomingCall: incomingCall, completion: dismisserCompletion)))
    }
    
}

extension PermissionAlertRouter: PermissionAlertRouting {
    
    func audioPermission(
        modal: Bool,
        incomingCall: Bool,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        
        if modal && deviceHandler.shouldAskForAudioPermissions {
            modalAudioPermissionForIncomingCall(incomingCall: incomingCall, completion: completion)
            
        } else {
            deviceHandler.requestAudioPermission(handler: completion)
        }
    }
    
    func alertAudioPermission(incomingCall: Bool) {
        modalPresenter(.alert(.audio(incomingCall: incomingCall, completion: openSettings)))
    }
    
    func alertVideoPermission() {
        modalPresenter(.alert(.video(completion: openSettings)))
    }
    
    func alertPhotosPermission() {
        modalPresenter(.alert(.photo(completion: openSettings)))
    }
    
    func presentModalNotificationsPermissionPrompt() {
        let dismisserCompletion: (Dismisser) -> Void = { dismisser in
            deviceHandler.notificationsPermission { granted in
                if granted {
                    notificationRegisterer()
                }
                dismisser()
            }
        }
        modalPresenter(.custom(.notifications(completion: dismisserCompletion)))
    }
    
    // this will ask only for audio if `videoCall == false`
    // if user denies, will present alert
    // if user provides audio access for nonVideo call, `granted` is called
    // if `videoCall == true`, will ask for audio permission once user
    // provides access to audio
    // if user denies video access, alert will be shown
    // if user gives audio and video permission for video call, `granted` is called
    func requestPermissionsFor(
        videoCall: Bool,
        granted: @escaping () -> Void
    ) {
        let incomingCall = false
        audioPermission(
            modal: true,
            incomingCall: incomingCall
        ) { audioPermissionGranted in
            guard audioPermissionGranted else {
                alertAudioPermission(incomingCall: false)
                return
            }
            
            // if this is audio, we are good and we can call granted
            guard videoCall else {
                granted()
                return
            }
            
            deviceHandler.requestVideoPermission { videoPermissionGranted in
                if videoPermissionGranted {
                    granted()
                } else {
                    alertVideoPermission()
                }
            }
        }
    }
}
