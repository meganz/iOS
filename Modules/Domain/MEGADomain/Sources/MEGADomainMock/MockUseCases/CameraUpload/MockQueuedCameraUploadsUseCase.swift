import MEGADomain

public struct MockQueuedCameraUploadsUseCase: QueuedCameraUploadsUseCaseProtocol {
    private let items: [CameraAssetUploadEntity]
    
    public init(items: [CameraAssetUploadEntity] = []) {
        self.items = items
    }
    
    public func queuedCameraUploads(
        startingFrom cursor: QueuedCameraUploadCursorEntity?,
        isForward: Bool,
        limit: Int?
    ) async throws -> [CameraAssetUploadEntity] {
        guard !items.isEmpty else {
            return []
        }
        
        let resolvedLimit = limit ?? items.count
        
        if let cursor = cursor {
            guard let startIndex = items.firstIndex(where: { $0.localIdentifier == cursor.localIdentifier }) else {
                return []
            }
            
            if isForward {
                let nextIndex = startIndex + 1
                guard nextIndex < items.count else { return [] }
                
                let endIndex = min(nextIndex + resolvedLimit, items.count)
                return Array(items[nextIndex..<endIndex])
            } else {
                let startOffset = max(0, startIndex - resolvedLimit)
                return Array(items[startOffset..<startIndex]).reversed()
            }
        } else {
            let endIndex = min(resolvedLimit, items.count)
            return Array(items[0..<endIndex])
        }
    }
}
