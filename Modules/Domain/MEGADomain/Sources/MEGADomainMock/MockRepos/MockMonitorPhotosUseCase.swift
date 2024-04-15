import MEGADomain
import MEGASwift

public struct MockMonitorPhotosUseCase: MonitorPhotosUseCaseProtocol {
    private let monitorPhotosAsyncSequence: AnyAsyncSequence<Result<[NodeEntity], Error>>
    
    public init(monitorPhotosAsyncSequence: AnyAsyncSequence<Result<[NodeEntity], Error>> = EmptyAsyncSequence<Result<[NodeEntity], Error>>().eraseToAnyAsyncSequence()) {
        self.monitorPhotosAsyncSequence = monitorPhotosAsyncSequence
    }
    
    public func monitorPhotos(filterOptions: PhotosFilterOptionsEntity) async -> AnyAsyncSequence<Result<[NodeEntity], Error>> {
        monitorPhotosAsyncSequence
    }
}
