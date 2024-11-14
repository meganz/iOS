import MEGADomain
import MEGASdk
import MEGASwift

public struct EventRepository: EventRepositoryProtocol {
    
    public static var newRepo: EventRepository {
        EventRepository(eventProvider: EventProvider(sdk: .sharedSdk))
    }
    
    private let eventProvider: any EventProviderProtocol
    
    public init(eventProvider: some EventProviderProtocol) {
        self.eventProvider = eventProvider
    }
    
    public var event: AnyAsyncSequence<EventEntity> {
        eventProvider.event
    }
}
