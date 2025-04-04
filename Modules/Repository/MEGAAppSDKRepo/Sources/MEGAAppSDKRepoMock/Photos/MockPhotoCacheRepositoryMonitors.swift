@preconcurrency import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

public struct MockPhotoCacheRepositoryMonitors: PhotoCacheRepositoryMonitorsProtocol {
    public let photosUpdatedAsyncSequence: AnyAsyncSequence<[NodeEntity]>
    
    public let monitorPhotoNodeUpdatesCountSubject = CurrentValueSubject<Int, Never>(0)
    public let monitorCacheInvalidationTriggersCountSubject  = CurrentValueSubject<Int, Never>(0)
    
    private let monitorPhotoNodeUpdates: AnyAsyncSequence<Void>
    private let monitorCacheInvalidationTriggers: AnyAsyncSequence<Void>
    
    public init(photosUpdatedAsyncSequence: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence<[NodeEntity]>().eraseToAnyAsyncSequence(),
                monitorPhotoNodeUpdates: AnyAsyncSequence<Void> = EmptyAsyncSequence<Void>().eraseToAnyAsyncSequence(),
                monitorCacheInvalidationTriggers: AnyAsyncSequence<Void> = EmptyAsyncSequence<Void>().eraseToAnyAsyncSequence()) {
        self.photosUpdatedAsyncSequence = photosUpdatedAsyncSequence
        self.monitorPhotoNodeUpdates = monitorPhotoNodeUpdates
        self.monitorCacheInvalidationTriggers = monitorCacheInvalidationTriggers
    }
    
    public func monitorPhotoNodeUpdates() async {
        monitorPhotoNodeUpdatesCountSubject.send(monitorPhotoNodeUpdatesCountSubject.value + 1)
        for await _ in monitorPhotoNodeUpdates { }
    }
    
    public func monitorCacheInvalidationTriggers() async {
        monitorCacheInvalidationTriggersCountSubject.send(monitorCacheInvalidationTriggersCountSubject.value + 1)
        for await _ in monitorCacheInvalidationTriggers { }
    }
}
