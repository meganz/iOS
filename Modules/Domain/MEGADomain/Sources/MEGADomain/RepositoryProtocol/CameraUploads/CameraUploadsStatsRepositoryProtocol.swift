import Foundation
import MEGASwift

/// Repo that provides information relating to the current active status of the CameraUploads in the application. 
/// This will monitor our active CameraUpload operation and provide the necessary information to gauge state of all operations.
public protocol CameraUploadsStatsRepositoryProtocol: RepositoryProtocol, Sendable {
    var photosUploadPausedReason: AnyAsyncSequence<CameraUploadMediaTypePausedReasonEntity> { get }
    var videosUploadPausedReason: AnyAsyncSequence<CameraUploadMediaTypePausedReasonEntity> { get }
    
    ///  Provides current CameraUploadStatsEntity relating to the status of active camera uploads occurring in the application.
    /// - Returns: CameraUploadStatsEntity containing stats of uploads at the call of this function.
    func currentUploadStats() async throws -> CameraUploadStatsEntity
    
    ///  AsyncSequence that fires off CameraUploadStatsEntity relating to the status of active camera uploads occurring in the application.
    ///   A new stats update should be triggered when uploads have had a state change. This includes completions, failures or paused
    /// - Returns: AsyncSequence that emits CameraUploadStatsEntity, this sequence will continue to remain active and cancel only from cooperative cancellation. Use this sequence appropriately.
    func monitorChangedUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity>
}
