import Foundation
import FirebaseCrashlytics

struct NodeBackupRecord: Codable {
    let date: Date
    let nodeHandle: MEGAHandle
}

final class BackupRecorder: NSObject {
    private enum Constants {
        static let recordCacheKey = "LastBackupRecordKey"
    }
    
    private var debouncer = Debouncer(delay: 1, dispatchQueue: DispatchQueue.global(qos: .utility))
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
        guard let node = notification.userInfo?[MEGANodeInfoKey] as? MEGANode else {
            return
        }
        
        debouncer.start {
            self.recordLastBackupNode(node)
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
        CameraUploadManager.shared().loadCurrentUploadStats { stats, error in
            guard stats?.isUploadCompleted == true else {
                return
            }
            
            NotificationCenter.default.post(name: NSNotification.Name.MEGACameraUploadComplete, object: nil)
            self.hasCameraUploadsFinishedProcessing = false
        }
    }
    
    // MARK: - last backup node
    private func recordLastBackupNode(_ node: MEGANode) {
        let record = NodeBackupRecord(date: Date(), nodeHandle: node.handle)
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
