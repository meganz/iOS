import MEGAAppPresentation
import MEGADomain
import MEGARepo

extension TransferSessionManager {
    @objc func restoreProgressReporting(for tasks: [URLSessionTask]) {
        guard let repository = makeCameraUploadTransferProgressRepository() else { return }
        
        var localIdentifierRestoredProgress: [CameraUploadLocalIdentifierEntity: RestoredLocalIdentifierProgress] = [:]
        
        for task in tasks {
            guard let taskDescription = task.taskDescription,
                  let taskInfo = taskDescription.parseTaskInfo() else { continue }
            let progress = localIdentifierRestoredProgress[taskInfo.localIdentifier] ?? RestoredLocalIdentifierProgress(
                taskIdentifierForChunk: [task.taskIdentifier: taskInfo.chunkIndex], sentPerChunk: [:], expectedBytesPerChunk: [:])
            
            var currentTaskIdentifiersForChunk = progress.taskIdentifierForChunk
            currentTaskIdentifiersForChunk[task.taskIdentifier] = taskInfo.chunkIndex
            
            var currentSentByChunk = progress.sentPerChunk
            currentSentByChunk[taskInfo.chunkIndex] = task.countOfBytesSent
            
            var currentExpectedBytesPerChunk = progress.expectedBytesPerChunk
            currentExpectedBytesPerChunk[taskInfo.chunkIndex] = task.countOfBytesExpectedToSend
            
            localIdentifierRestoredProgress[taskInfo.localIdentifier] = RestoredLocalIdentifierProgress(
                taskIdentifierForChunk: currentTaskIdentifiersForChunk,
                sentPerChunk: currentSentByChunk,
                expectedBytesPerChunk: currentExpectedBytesPerChunk)
        }
        
        for (localIdentifier, progress) in localIdentifierRestoredProgress {
            repository.restoreTasks(
                for: localIdentifier,
                taskIdentifierForChunk: progress.taskIdentifierForChunk,
                totalBytesSent: progress.sentPerChunk.values.reduce(0, +),
                expectedBytesPerChunk: progress.expectedBytesPerChunk)
        }
    }
    
    @objc func makeCameraUploadTransferProgressRepository() -> CameraUploadTransferProgressOCRepository? {
        guard DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosCameraUploadBreakdown) else { return nil }
        return CameraUploadTransferProgressOCRepository()
    }
}

private struct RestoredLocalIdentifierProgress {
    let taskIdentifierForChunk: [Int: Int]
    let sentPerChunk: [Int: Int64]
    let expectedBytesPerChunk: [Int: Int64]
}
