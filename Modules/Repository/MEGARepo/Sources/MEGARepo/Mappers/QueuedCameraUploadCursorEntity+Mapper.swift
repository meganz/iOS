import MEGADomain

extension QueuedCameraUploadCursorEntity {
    func toQueuedCameraUploadCursorDTO() -> QueuedCameraUploadCursorDTO {
        .init(
            localIdentifier: localIdentifier,
            creationDate: creationDate)
    }
}
