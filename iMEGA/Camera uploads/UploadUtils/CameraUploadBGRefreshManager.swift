import BackgroundTasks

final class CameraUploadBGRefreshManager {
    private enum Constants {
        static let identifier = "mega.iOS.cameraUpload.backgroundFetch"
        static let backgroundFetchInterval: TimeInterval = 3 * 3600
    }
    
    static let shared = CameraUploadBGRefreshManager()
    private init() { }
    let backgroundRefreshPerfomer = CameraUploadBackgroundRefreshPerformer()
    
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Constants.identifier, using: nil) { (task: BGTask) in
            guard let task = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            
            self.schedule()
            MEGALogDebug("Perform background Refresh")
            self.backgroundRefreshPerfomer.performBackgroundRefresh(with: task)
        }
    }

    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Constants.backgroundFetchInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            MEGALogDebug("Could not schedule camera upload app refresh: \(error)")
        }
    }
    
    func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Constants.identifier)
    }
}
