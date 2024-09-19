import MEGADomain
import MEGASwift

public struct MockMonitorPhotosUseCase: MonitorPhotosUseCaseProtocol {
    public enum Invocation: Sendable, Equatable {
        case monitorPhotos(filterOptions: PhotosFilterOptionsEntity)
    }
    private actor State {
        var invocations: [Invocation] = []
        
        func addInvocation(_ invocation: Invocation) {
            invocations.append(invocation)
        }
    }
    private let state = State()
    private let monitorPhotosAsyncSequence: AnyAsyncSequence<Result<[NodeEntity], Error>>
    
    public init(monitorPhotosAsyncSequence: AnyAsyncSequence<Result<[NodeEntity], Error>> = EmptyAsyncSequence<Result<[NodeEntity], Error>>().eraseToAnyAsyncSequence()) {
        self.monitorPhotosAsyncSequence = monitorPhotosAsyncSequence
    }
    
    public func monitorPhotos(filterOptions: PhotosFilterOptionsEntity) async -> AnyAsyncSequence<Result<[NodeEntity], Error>> {
        await state.addInvocation(.monitorPhotos(filterOptions: filterOptions))
        
        return if filterOptions.contains(.favourites) {
            monitorPhotosAsyncSequence
                .map {
                    $0.map { $0.filter(\.isFavourite) }
                }.eraseToAnyAsyncSequence()
        } else {
            monitorPhotosAsyncSequence
        }
    }
}
extension MockMonitorPhotosUseCase {
    public var invocations: [Invocation] {
        get async {
            await state.invocations
        }
    }
}
