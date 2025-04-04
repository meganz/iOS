import MEGADomain
import MEGASwift

public struct EventRepository: EventRepositoryProtocol {
    
    public static var newRepo: EventRepository {
        EventRepository()
    }
    
    public var eventUpdates: AnyAsyncSequence<EventEntity> {
        MEGAUpdateHandlerManager.shared.eventUpdates
    }
}
