import Foundation
import MEGASwift

public protocol MonitorCameraUploadUseCaseProtocol {
    var monitorUploadStatus: AnyAsyncSequence<Result<CameraUploadStatsEntity, Error>> { get }
}
