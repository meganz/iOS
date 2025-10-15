import MEGADomain
import MEGARepo

@objc final class CameraUploadTransferProgressOCRepository: NSObject, @unchecked Sendable {
    
    private let repository = CameraUploadTransferProgressRepository.shared
    
    @objc func registerTask(identifier: Int, description: CameraUploadTaskDescriptionEntity?, totalBytesExpectedToWrite: Int64) {
        guard let info = description?.parseTaskInfo() else { return }
        MEGALogDebug("[Camera Upload] register upload task for identifier: \(identifier) task description: \(description ?? "") totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        Task {
            await repository.registerTask(
                identifier: identifier,
                info: info,
                totalBytesExpectedToWrite: totalBytesExpectedToWrite
            )
        }
    }
    
    @objc func updateProgress(identifier: Int, description: CameraUploadTaskDescriptionEntity, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let info = description.parseTaskInfo() else { return }
        
        Task {
            await repository.updateTaskProgress(
                identifier: identifier,
                info: info,
                totalBytesSent: totalBytesSent,
                totalBytesExpected: totalBytesExpectedToSend)
        }
    }
    
    @objc func completeTask(identifier: Int, description: CameraUploadTaskDescriptionEntity) {
        guard let info = description.parseTaskInfo() else { return }
        MEGALogDebug("[Camera Upload] complete upload task for identifier: \(identifier) task description: \(description)")
        
        Task {
            await repository.completeTask(identifier: identifier, info: info)
        }
    }
    
    @objc func restoreTasks(for localIdentifier: CameraUploadLocalIdentifierEntity, taskIdentifierForChunk: [Int: Int], totalBytesSent: Int64, expectedBytesPerChunk: [Int: Int64]) {
        MEGALogDebug("[Camera Upload] restore upload task for identifier: \(localIdentifier) taskIdentifierForChunk: \(taskIdentifierForChunk) totalBytesSent: \(totalBytesSent) expectedBytesPerChunk: \(expectedBytesPerChunk)")
        
        Task {
            await repository.restoreTasks(
                for: localIdentifier,
                taskIdentifierForChunk: taskIdentifierForChunk,
                totalBytesSent: totalBytesSent,
                expectedBytesPerChunk: expectedBytesPerChunk)
        }
    }
}
