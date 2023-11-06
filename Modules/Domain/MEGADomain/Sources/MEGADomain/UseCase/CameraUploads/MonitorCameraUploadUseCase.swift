import Foundation
import MEGASwift

public protocol MonitorCameraUploadUseCaseProtocol {
    var monitorUploadStatus: AnyAsyncSequence<CameraUploadStatsEntity> { get }
}
