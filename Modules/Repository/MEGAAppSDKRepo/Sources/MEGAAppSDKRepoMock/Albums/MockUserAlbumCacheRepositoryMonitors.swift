@preconcurrency import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

public final class MockUserAlbumCacheRepositoryMonitors: UserAlbumCacheRepositoryMonitorsProtocol {
    public let setUpdateAsyncSequences: AnyAsyncSequence<[SetEntity]>
    public let setElementUpdateAsyncSequences: AnyAsyncSequence<[SetElementEntity]>
    public let setElementUpdateOnSetsAsyncSequences: AnyAsyncSequence<[SetEntity]>
    public let setsUpdatedPublisher: AnyPublisher<[SetEntity], Never>
    public let setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never>
    
    public let monitorSetUpdatesCountSubject = CurrentValueSubject<Int, Never>(0)
    public let monitorSetElementUpdatesCountSubject  = CurrentValueSubject<Int, Never>(0)
    public let monitorCacheInvalidationTriggersCountSubject  = CurrentValueSubject<Int, Never>(0)
    
    public init(setUpdateAsyncSequences: AnyAsyncSequence<[SetEntity]> = EmptyAsyncSequence<[SetEntity]>().eraseToAnyAsyncSequence(),
                setElementUpdateAsyncSequences: AnyAsyncSequence<[SetElementEntity]> = EmptyAsyncSequence<[SetElementEntity]>().eraseToAnyAsyncSequence(),
                setElementUpdateOnSetsAsyncSequences: AnyAsyncSequence<[SetEntity]> = EmptyAsyncSequence<[SetEntity]>().eraseToAnyAsyncSequence(),
                setsUpdatedPublisher: AnyPublisher<[SetEntity], Never> = Empty().eraseToAnyPublisher(),
                setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never> = Empty().eraseToAnyPublisher()) {
        self.setUpdateAsyncSequences = setUpdateAsyncSequences
        self.setElementUpdateAsyncSequences = setElementUpdateAsyncSequences
        self.setElementUpdateOnSetsAsyncSequences = setElementUpdateOnSetsAsyncSequences
        self.setsUpdatedPublisher = setsUpdatedPublisher
        self.setElementsUpdatedPublisher = setElementsUpdatedPublisher
    }
    
    public func monitorSetUpdates() async {
        monitorSetUpdatesCountSubject.send(monitorSetUpdatesCountSubject.value + 1)
    }
    
    public func monitorSetElementUpdates() async {
        monitorSetElementUpdatesCountSubject.send(monitorSetElementUpdatesCountSubject.value + 1)
    }
    
    public func monitorCacheInvalidationTriggers() async {
        monitorCacheInvalidationTriggersCountSubject.send(monitorCacheInvalidationTriggersCountSubject.value + 1)
    }
}
