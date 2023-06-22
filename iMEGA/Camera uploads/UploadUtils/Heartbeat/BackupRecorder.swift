import FirebaseCrashlytics
import Foundation
import MEGADomain
import MEGAFoundation

struct NodeBackupRecord: Codable {
    let date: Date
    let nodeHandle: HandleEntity
}

final class BackupRecorder: NSObject {
    private enum Constants {
        static let recordCacheKey = "LastBackupRecordKey"
    }
    
    private let debouncer = Debouncer(delay: 1, dispatchQueue: DispatchQueue.global(qos: .utility))
    private var hasCameraUploadsFinishedProcessing = false
    
    // MARK: - recoding update
    func startRecordingBackupUpdate() {
        stopRecordingBackupUpdate()
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveNodeUploadCompleteNotification(_:)), name: NSNotification.Name.MEGACameraUploadNodeUploadComplete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveCameraUploadsFinishProcessingNotification), name: NSNotification.Name.MEGACameraUploadAllAssetsFinishedProcessing, object: nil)
    }
    
    func stopRecordingBackupUpdate() {
        NotificationCenter.default.removeObserver(self)
        hasCameraUploadsFinishedProcessing = false
    }
    
    @objc private func didReceiveNodeUploadCompleteNotification(_ notification: NSNotification) {
        guard let handle = (notification.userInfo?[MEGANodeHandleKey] as? NSNumber)?.uint64Value else {
            return
        }
        
        debouncer.start { [weak self] in
            guard let self = self else { return }
            self.recordLastBackupNode(handle: handle)
            if self.hasCameraUploadsFinishedProcessing {
                self.checkUploadStats()
            }
        }
    }
    
    @objc private func didReceiveCameraUploadsFinishProcessingNotification() {
        MEGALogDebug("[Camera Upload] heartbeat - received camera uploads finishes processing notification")
        hasCameraUploadsFinishedProcessing = true
    }
    
    private func checkUploadStats() {
        CameraUploadManager.shared().loadCurrentUploadStats { stats, _ in
            guard stats?.isUploadCompleted == true else {
                return
            }
            
            NotificationCenter.default.post(name: NSNotification.Name.MEGACameraUploadComplete, object: nil)
            self.hasCameraUploadsFinishedProcessing = false
        }
    }
    
    // MARK: - last backup node
    private func recordLastBackupNode(handle: HandleEntity) {
        let record = NodeBackupRecord(date: Date(), nodeHandle: handle)
        do {
            let data = try JSONEncoder().encode(record)
            UserDefaults.standard.set(data, forKey: Constants.recordCacheKey)
        } catch {
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    func fetchLastBackupRecord() -> NodeBackupRecord? {
        guard let data = UserDefaults.standard.data(forKey: Constants.recordCacheKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(NodeBackupRecord.self, from: data)
    }
}
