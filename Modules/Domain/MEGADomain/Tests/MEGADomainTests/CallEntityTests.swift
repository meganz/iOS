import MEGADomain
import MEGADomainMock
import XCTest

final class CallEntityTests: XCTestCase {
    func testReachingMaxParticipants_NoParticiants_NoLimits() {
        let call = CallEntity(
            callLimits: .init(durationLimit: 0, maxUsers: -1, maxClientsPerUser: 0, maxClients: 0)
        )
        XCTAssertFalse(call.hasReachedMaxCallParticipants)
    }
    
    func testReachingMaxParticipants_SomeParticipants_NoLimits() {
        let call = CallEntity(
            callLimits: .init(durationLimit: 0, maxUsers: -1, maxClientsPerUser: 0, maxClients: 0),
            numberOfParticipants: 2
        )
        XCTAssertFalse(call.hasReachedMaxCallParticipants)
    }
    
    func testReachingMaxParticipants_SomeParticipants_TheSameLimits() {
        let call = CallEntity(
            callLimits: .init(durationLimit: 0, maxUsers: 100, maxClientsPerUser: 0, maxClients: 0),
            numberOfParticipants: 100
        )
        XCTAssertTrue(call.hasReachedMaxCallParticipants)
    }
    
    func testReachingMaxParticipants_SomeParticipants_LowerLimits() {
        let call = CallEntity(
            callLimits: .init(durationLimit: 0, maxUsers: 99, maxClientsPerUser: 0, maxClients: 0),
            numberOfParticipants: 100
        )
        XCTAssertTrue(call.hasReachedMaxCallParticipants)
    }
    
    func testReachingMaxParticipants_SomeParticipants_HigherLimits() {
        let call = CallEntity(
            callLimits: .init(durationLimit: 0, maxUsers: 101, maxClientsPerUser: 0, maxClients: 0),
            numberOfParticipants: 100
        )
        XCTAssertFalse(call.hasReachedMaxCallParticipants)
    }
}
