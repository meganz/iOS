import MEGADomain
import MEGASwift

public struct MockMonitorPhotosUseCase: MonitorPhotosUseCaseProtocol {
    private let monitorPhotosAsyncSequence: AnyAsyncSequence<[NodeEntity]>
    
    public init(monitorPhotosAsyncSequence: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence<[NodeEntity]>().eraseToAnyAsyncSequence()) {
        self.monitorPhotosAsyncSequence = monitorPhotosAsyncSequence
    }
    
    public func monitorPhotos(filterOptions: PhotosFilterOptionsEntity) async throws -> AnyAsyncSequence<[NodeEntity]> {
        monitorPhotosAsyncSequence
    }
}
