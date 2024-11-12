import MEGADomain
import MEGASwift

private typealias NodeEntityFilter = (@Sendable (NodeEntity) -> Bool)

public struct MockMonitorPhotosUseCase: MonitorPhotosUseCaseProtocol {
    public enum Invocation: Sendable, Equatable {
        case monitorPhotos(filterOptions: PhotosFilterOptionsEntity, excludeSensitive: Bool)
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
    
    public func monitorPhotos(
        filterOptions: PhotosFilterOptionsEntity,
        excludeSensitive: Bool,
        searchText: String?
    ) async -> AnyAsyncSequence<Result<[NodeEntity], Error>> {
        await state.addInvocation(
            .monitorPhotos(filterOptions: filterOptions, excludeSensitive: excludeSensitive))
        
        let filters = makeFilters(
            filterOptions: filterOptions,
            excludeSensitive: excludeSensitive,
            searchText: searchText)
        
        return if filters.isEmpty {
            monitorPhotosAsyncSequence
        } else {
            monitorPhotosAsyncSequence.map {
                $0.map { $0.filter { node in filters.allSatisfy { $0(node) } } }
            }
            .eraseToAnyAsyncSequence()
        }
    }
    
    private func makeFilters(filterOptions: PhotosFilterOptionsEntity,
                             excludeSensitive: Bool,
                             searchText: String?) -> [NodeEntityFilter] {
        var filters = [NodeEntityFilter]()
        if filterOptions.contains(.favourites) {
            filters.append({ $0.isFavourite })
        }
        if excludeSensitive {
            filters.append({ !$0.isMarkedSensitive })
        }
        if let searchText {
            filters.append({ $0.name.localizedCaseInsensitiveContains(searchText) })
        }
        return filters
    }
}
extension MockMonitorPhotosUseCase {
    public var invocations: [Invocation] {
        get async {
            await state.invocations
        }
    }
}
