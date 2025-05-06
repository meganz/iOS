import DeviceCenter
import FirebaseCrashlytics
import Foundation
import MEGADomain
import MEGAL10n
import MEGAPreference

extension Notification.Name {
    static let didChangeCameraUploadsFolderName = Notification.Name("didChangeCameraUploadsFolderName")
}
 
final class BackupRegister {
    private let sdk: MEGASdk
    private let cameraUploadsUseCase: any CameraUploadsUseCaseProtocol
    
    @PreferenceWrapper(key: PreferenceKeyEntity.backupHeartbeatRegistrationId, defaultValue: nil, useCase: PreferenceUseCase.default)
    var cachedBackupId: HandleEntity?
    
    @PreferenceWrapper(key: PreferenceKeyEntity.hasUpdatedBackupToFixExistingBackupNameStorageIssue, defaultValue: false, useCase: PreferenceUseCase.default)
    var hasUpdatedBackup: Bool
    
    init(
        sdk: MEGASdk,
        cameraUploadsUseCase: any CameraUploadsUseCaseProtocol
    ) {
        self.sdk = sdk
        self.cameraUploadsUseCase = cameraUploadsUseCase
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTargetFolderUpdatedNotification), name: Notification.Name.MEGACameraUploadTargetFolderUpdatedInMemory, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveBusinessAccountExpiredNotification), name: Notification.Name.MEGABusinessAccountExpired, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveBusinessAccountActivatedNotification), name: Notification.Name.MEGABusinessAccountActivated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeCameraUploadsFolderNotification), name: Notification.Name.didChangeCameraUploadsFolderName, object: nil)
        
        registerCameraUploadNodeNameUpdate() 
    }
    
    deinit {
        removeCameraUploadNodeNameUpdate()
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
        updateBackup(state: .active)
    }
    
    @objc private func didChangeCameraUploadsFolderNotification() {
        Task {
            await updateCameraUploadsBackupName()
        }
    }
    
    // MARK: - Register backup
    
    func registerBackupIfNeeded() {
        MEGALogDebug("[Camera Upload] heartbeat - start registering backup")
        guard cachedBackupId == nil else {
            MEGALogDebug("[Camera Upload] heartbeat - find local cached backup \(type(of: sdk).base64Handle(forHandle: (cachedBackupId ?? 0)) ?? "")")
            enableBackupByTheUser()
            return
        }
        
        Task {
            do {
                let parentHandle = try await cameraUploadsUseCase.registerCameraUploadsBackup(
                    Strings.Localizable.General.cameraUploads
                )
                MEGALogDebug("[Camera Upload] heartbeat - register backup \(String(describing: type(of: sdk).base64Handle(forHandle: parentHandle))) success")
                cachedBackupId = parentHandle
            } catch {
                Crashlytics.crashlytics().record(error: error)
                MEGALogError("[Camera Upload] heartbeat - error when to register backup \(error)")
            }
        }
    }
    
    func registerCameraUploadNodeNameUpdate() {
        cameraUploadsUseCase.registerCameraUploadNodeNameUpdate {
            NotificationCenter.default.post(name: .didChangeCameraUploadsFolderName, object: nil)
        }
    }
    
    // MARK: - Disable backup by the user
    
    func disableBackupByTheUser() {
        updateBackup(state: .disabled)
        MEGALogDebug("[Camera Upload] heartbeat - backup disabled by the user")
    }
    
    // MARK: - Enable backup by the user
    
    func enableBackupByTheUser() {
        updateBackup(state: .active)
        MEGALogDebug("[Camera Upload] heartbeat - backup enabled by the user")
    }
    
    func removeCameraUploadNodeNameUpdate() {
        cameraUploadsUseCase.removeCameraUploadNodeNameUpdate()
    }
    
    // MARK: - Update backup status
    
    private func updateBackup(state: BackUpStateEntity = .active, subState: BackUpSubStateEntity = .noSyncError) {
        MEGALogDebug("[Camera Upload] heartbeat - start updating backup status")
        guard let backupId = cachedBackupId else {
            MEGALogDebug("[Camera Upload] heartbeat - skip updating backup as no local cached backup id")
            return
        }
        
        Task {
            do {
                try await cameraUploadsUseCase.updateCameraUploadsBackupState(
                    backupId,
                    state: state,
                    substate: subState
                )
                hasUpdatedBackup = true
            } catch {
                Crashlytics.crashlytics().record(error: error)
                MEGALogError("[Camera Upload] heartbeat - error when to update backup status \(String(describing: type(of: sdk).base64Handle(forHandle: backupId))) \(error)")
            }
        }
    }
    
    // MARK: - Update backup name
    
    private func updateCameraUploadsBackupName() async {
        MEGALogDebug("[Camera Upload] heartbeat - start updating backup name")
        guard let backupId = cachedBackupId else {
            MEGALogDebug("[Camera Upload] heartbeat - skip updating backup as no local cached backup id")
            return
        }
        
        do {
            try await cameraUploadsUseCase.updateCameraUploadsBackupName(
                backupId
            )
            NotificationCenter.default.post(name: .shouldChangeCameraUploadsBackupName, object: nil)
        } catch {
            Crashlytics.crashlytics().record(error: error)
            MEGALogError("[Camera Upload] heartbeat - error when to update backup name \(String(describing: type(of: sdk).base64Handle(forHandle: backupId))) \(error)")
        }
    }
    
    func updateBackupRetrospectivelyToFixExistingBackupNameEncodingAndStorageIssue() {
        if !hasUpdatedBackup {
            updateBackup()
        }
    }
}
