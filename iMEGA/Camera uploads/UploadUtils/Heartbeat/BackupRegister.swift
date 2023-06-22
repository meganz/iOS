import FirebaseCrashlytics
import Foundation
import MEGADomain

final class BackupRegister {
    
    private let sdk: MEGASdk
    
    @PreferenceWrapper(key: .backupHeartbeatRegistrationId, defaultValue: nil, useCase: PreferenceUseCase.default)
    var cachedBackupId: HandleEntity?
    
    @PreferenceWrapper(key: .hasUpdatedBackupToFixExistingBackupNameStorageIssue, defaultValue: false, useCase: PreferenceUseCase.default)
    var hasUpdatedBackup: Bool
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTargetFolderUpdatedNotification), name: Notification.Name.MEGACameraUploadTargetFolderUpdatedInMemory, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveBusinessAccountExpiredNotification), name: Notification.Name.MEGABusinessAccountExpired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveBusinessAccountActivatedNotification), name: Notification.Name.MEGABusinessAccountActivated, object: nil)
    }
    
    // MARK: - Notification
    @objc private func didReceiveTargetFolderUpdatedNotification() {
        if CameraUploadManager.isCameraUploadEnabled {
            updateBackup()
        }
    }
    
    @objc private func didReceiveBusinessAccountExpiredNotification() {
        MEGALogDebug("[Camera Upload] heartbeat - business account expired notification")
        updateBackup(state: .temporaryDisabled, subState: .accountExpired)
    }
    
    @objc private func didReceiveBusinessAccountActivatedNotification() {
        MEGALogDebug("[Camera Upload] heartbeat - business account activated notification")
        updateBackup(state: .active, subState: .noSyncError)
    }
    
    // MAKR: - Register backup
    func registerBackupIfNeeded() {
        MEGALogDebug("[Camera Upload] heartbeat - start registering backup")
        guard cachedBackupId == nil else {
            MEGALogDebug("[Camera Upload] heartbeat - find local cached backup \(type(of: sdk).base64Handle(forHandle: (cachedBackupId ?? 0)) ?? "")")
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
                                    name: Strings.Localizable.cameraUploadsLabel,
                                    state: .active,
                                    delegate: HeartbeatRequestDelegate { [weak self, sdkType = type(of: self.sdk)] result in
                switch result {
                case .failure(let error):
                    Crashlytics.crashlytics().record(error: error)
                    MEGALogError("[Camera Upload] heartbeat - error when to register backup \(error)")
                case .success(let request):
                    self?.cachedBackupId = request.parentHandle
                    MEGALogDebug("[Camera Upload] heartbeat - register backup \(sdkType.base64Handle(forHandle: request.parentHandle) ?? "") success")
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
        
        sdk.unregisterBackup(backupId, delegate: HeartbeatRequestDelegate { [sdkType = type(of: sdk)] result in
            switch result {
            case .failure(let error):
                Crashlytics.crashlytics().record(error: error)
                MEGALogError("[Camera Upload] heartbeat - error when to unregister backup \(sdkType.base64Handle(forHandle: backupId) ?? "")")
            case .success:
                MEGALogDebug("[Camera Upload] heartbeat - unregister backup \(sdkType.base64Handle(forHandle: backupId) ?? "") success")
            }
        })
    }
    
    // MARK: - Update backup status
    private func updateBackup(state: BackUpState = .active, subState: BackUpSubState = .noSyncError) {
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
                                  backupName: Strings.Localizable.cameraUploadsLabel,
                                  state: state,
                                  subState: subState,
                                  delegate: HeartbeatRequestDelegate { [sdkType = type(of: self.sdk), weak self] result in
                
                self?.hasUpdatedBackup = true
                
                switch result {
                case .failure(let error):
                    Crashlytics.crashlytics().record(error: error)
                    MEGALogError("[Camera Upload] heartbeat - error when to update backup \(sdkType.base64Handle(forHandle: backupId) ?? "") \(error)")
                case .success:
                    MEGALogDebug("[Camera Upload] heartbeat - update backup \(sdkType.base64Handle(forHandle: backupId) ?? "") success. state:\(state.rawValue), substate: \(subState.rawValue)")
                }
            })
        }
    }
    
    func updateBackupRetrospectivelyToFixExistingBackupNameEncodingAndStorageIssue() {
        if !hasUpdatedBackup {
            updateBackup()
        }
    }
}
