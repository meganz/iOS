import Foundation
import MEGAAnalyticsDomain

public final class MockAnalyticsRepository: AnalyticsRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockAnalyticsRepository {
        MockAnalyticsRepository()
    }
    
    private let queue = DispatchQueue(label: "com.mega.MockAnalyticsRepository")
    
    public private(set) var sendAnalyticsEvent_Calls = [EventEntity]()
    
    public func sendAnalyticsEvent(_ eventEntity: EventEntity) {
        queue.sync {
            sendAnalyticsEvent_Calls.append(eventEntity)
        }
    }
}
