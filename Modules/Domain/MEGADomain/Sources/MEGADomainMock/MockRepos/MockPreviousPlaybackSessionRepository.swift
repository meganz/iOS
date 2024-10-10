import Foundation
import MEGADomain

public final class MockPreviousPlaybackSessionRepository: PreviousPlaybackSessionRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockPreviousPlaybackSessionRepository { .init() }
    
    public var mockTimeIntervals: [String: TimeInterval]
    
    public init(mockTimeIntervals: [String: TimeInterval] = [String: TimeInterval]()) {
        self.mockTimeIntervals = mockTimeIntervals
    }
    
    public func timeInterval(for fingerprint: FingerprintEntity) -> TimeInterval? {
        mockTimeIntervals[fingerprint]
    }
    
    public func saveTimeInterval(_ timeInterval: TimeInterval, for fingerprint: FingerprintEntity) {
        mockTimeIntervals[fingerprint] = timeInterval
    }
    
    public func removeSavedTimeInterval(for fingerprint: FingerprintEntity) {
        mockTimeIntervals[fingerprint] = nil
    }
}
