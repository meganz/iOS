import MEGADomain
import MEGARepo

extension CameraAssetUploadStatusDTO {
    func toCameraAssetUploadStatus() -> CameraAssetUploadStatus {
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

extension CameraAssetUploadStatus {
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
        @unknown default: .unknown
        }
    }
}
