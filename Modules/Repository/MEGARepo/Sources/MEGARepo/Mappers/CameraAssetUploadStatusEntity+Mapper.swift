import MEGADomain

extension CameraAssetUploadStatusEntity {
    func toCameraAssetUploadStatusDTO() -> CameraAssetUploadStatusDTO {
        switch self {
        case .unknown: .unknown
        case .notStarted: .notStarted
        case .notReady: .notReady
        case .queuedUp: .queuedUp
        case .processing: .processing
        case .uploading: .uploading
        case .cancelled: .cancelled
        case .failed: .failed
        case .done: .done
        }
    }
}

extension [CameraAssetUploadStatusEntity] {
    func toCameraAssetUploadStatusDTOs() -> [CameraAssetUploadStatusDTO] {
        map { $0.toCameraAssetUploadStatusDTO() }
    }
}

extension CameraAssetUploadStatusDTO {
    func toCameraAssetUploadStatusEntity() -> CameraAssetUploadStatusEntity {
        switch self {
        case .unknown: .unknown
        case .notStarted: .notStarted
        case .notReady: .notReady
        case .queuedUp: .queuedUp
        case .processing: .processing
        case .uploading: .uploading
        case .cancelled: .cancelled
        case .failed: .failed
        case .done: .done
        }
    }
}
