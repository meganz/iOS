import Foundation
import FirebaseCrashlytics

final class BackupRegister {
    
    private let sdk: MEGASdk
    
    @PreferenceWrapper(key: .backupHeartbeatRegistrationId, defaultValue: nil)
    var cachedBackupId: MEGAHandle?
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTargetFolderUpdatedNotification), name: Notification.Name.MEGACameraUploadTargetFolderUpdatedInMemory, object: nil)
    }
    
    // MARK: - Notification
    @objc private func didReceiveTargetFolderUpdatedNotification() {
        if CameraUploadManager.isCameraUploadEnabled {
            updateBackup()
        }
    }
    
    // MAKR: - Register backup
    func registerBackupIfNeeded() {
        MEGALogDebug("[Camera Upload] heartbeat - start registering backup")
        guard cachedBackupId == nil else {
            MEGALogDebug("[Camera Upload] heartbeat - find local cached backup \(cachedBackupId ?? 0)")
            return
        }
        
        CameraUploadNodeAccess.shared.loadNode { node, error in
            guard let node = node else {
                if let error = error {
                    Crashlytics.crashlytics().record(error: error)
                    MEGALogError("[Camera Upload] heartbeat - error when to load node \(error)")
                }
                return
            }
            
            self.sdk.registerBackup(.cameraUploads,
                                    targetNode: node,
                                    folderPath: MEGACameraUploadsFolderPath,
                                    name: NSLocalizedString("cameraUploadsLabel", comment: ""),
                                    state: .active,
                                    delegate: HeartbeatRequestDelegate { [weak self] result in
                                        switch result {
                                        case .failure(let error):
                                            Crashlytics.crashlytics().record(error: error)
                                            MEGALogError("[Camera Upload] heartbeat - error when to register backup \(error)")
                                        case .success(let request):
                                            self?.cachedBackupId = request.parentHandle
                                            MEGALogDebug("[Camera Upload] heartbeat - register backup \(request.parentHandle) success")
                                        }
                                    })
        }
    }
    
    // MARK: - Unregister backup
    func unregisterBackup() {
        MEGALogDebug("[Camera Upload] heartbeat - start unregistering backup")
        guard let backupId = cachedBackupId else {
            MEGALogDebug("[Camera Upload] heartbeat - skip unregistering as no local cached backup id")
            return
        }
        
        $cachedBackupId.remove()
        
        sdk.unregisterBackup(backupId, delegate: HeartbeatRequestDelegate { result in
            switch result {
            case .failure(let error):
                Crashlytics.crashlytics().record(error: error)
                MEGALogError("[Camera Upload] heartbeat - error when to unregister backup \(backupId)")
            case .success:
                MEGALogDebug("[Camera Upload] heartbeat - unregister backup \(backupId) success")
            }
        })
    }
    
    // MAKR: - Update backup registration
    private func updateBackup() {
        MEGALogDebug("[Camera Upload] heartbeat - start updating backup")
        guard let backupId = cachedBackupId else {
            MEGALogDebug("[Camera Upload] heartbeat - skip updating backup as no local cached backup id")
            return
        }
        
        CameraUploadNodeAccess.shared.loadNode { node, error in
            guard let node = node else {
                if let error = error {
                    Crashlytics.crashlytics().record(error: error)
                    MEGALogError("[Camera Upload] heartbeat - error when to load node \(error)")
                }
                return
            }
            
            self.sdk.updateBackup(backupId,
                                  backupType: .cameraUploads,
                                  targetNode: node,
                                  folderPath: MEGACameraUploadsFolderPath,
                                  state: .active,
                                  delegate: HeartbeatRequestDelegate { result in
                                    switch result {
                                    case .failure(let error):
                                        Crashlytics.crashlytics().record(error: error)
                                        MEGALogError("[Camera Upload] heartbeat - error when to update backup \(backupId) \(error)")
                                    case .success:
                                        MEGALogDebug("[Camera Upload] heartbeat - update backup \(backupId) success")
                                    }
                                  })
            
        }
    }
}
