import MEGADomain
import MEGARepo

extension CameraUploadOperation {
    @objc func prepareThumbnailAndPreviewFiles() async -> Bool {
        if isCancelled {
            finish(with: .cancelled)
            return false
        }
        
        let fileAttributeGenerator = FileAttributeGenerator(sourceURL: uploadInfo.attributeImageURL,
                                                            pixelWidth: uploadInfo.asset.pixelWidth,
                                                            pixelHeight: uploadInfo.asset.pixelHeight)
        
        let thumbnailCreated = await fileAttributeGenerator.createThumbnail(at: uploadInfo.thumbnailURL)
        if isCancelled {
            finish(with: .cancelled)
            return false
        }
        if !thumbnailCreated {
            return false
        }
        
        let previewCreated = await fileAttributeGenerator.createPreview(at: uploadInfo.previewURL)
        return previewCreated
    }
    
    /// Creates a task description string for a given photo library asset and its upload chunk.
    ///
    /// - Important:
    ///   When using background `NSURLSession` for chunked file uploads:
    ///   - Already uploaded chunks are **not re-uploaded** if the app is force quit
    ///     and later restored. The system ensures that successfully transmitted
    ///     network chunks remain uploaded.
    ///   - What is lost is **progress granularity**: per-chunk progress callbacks that
    ///     occurred while the app was terminated will not be replayed. On relaunch,
    ///     you will only get the aggregate `countOfBytesSent` value for the task.
    ///   - This means the `chunkIndex` is useful for debugging and correlating tasks,
    ///     but not for recovering fine-grained progress after app termination.
    ///
    /// - Parameters:
    ///   - localIdentifier: The asset identifier (not guaranteed to be stable across apps).
    ///   - chunkIndex: The index of the current chunk being uploaded.
    ///   - totalChunks: The total number of chunks that make up the full file.
    /// - Returns: A string representation of the task description that can be
    ///   attached to the `NSURLSessionTask`.
    @objc func makeTaskDescription(for localIdentifier: String, chunkIndex: Int, totalChunks: Int) -> String {
        // Check if the reporter was injected via `UploadOperationFactory makeCameraUploadTransferProgressRepository`
        guard transferProgressRepository != nil else {
            return localIdentifier
        }
        return CameraUploadTaskDescriptionEntity.create(localIdentifier: localIdentifier, chunkIndex: chunkIndex, totalChunks: totalChunks)
    }
    
    @objc func registerTaskWithProgressReporter(_ task: URLSessionTask) {
        guard let transferProgressRepository, // Check if the reporter was injected via `UploadOperationFactory makeCameraUploadTransferProgressRepository`
              let taskDescription = task.taskDescription else { return }
        
        var totalBytesExpectedToWrite: Int64 = 0
        if let chunkPath = task.originalRequest?.url?.path() {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: chunkPath)
                if let fileSize = attributes[.size] as? UInt64 {
                    totalBytesExpectedToWrite = Int64(clamping: fileSize)
                }
            } catch {
                print("[Camera Uploads] Failed to get chunk attributes: \(error)")
            }
        }
        
        transferProgressRepository.registerTask(
            identifier: task.taskIdentifier,
            description: taskDescription,
            totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
}
