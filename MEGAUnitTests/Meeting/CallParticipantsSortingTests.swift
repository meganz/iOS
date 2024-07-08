import MEGADomain
import XCTest

/// This class is intended to test Array extension method:
/// public func sortByRaiseHand(call: CallEntity?) -> [CallParticipantEntity]
class CallParticipantsSortingTests: XCTestCase {
    func test_sortCallParticipantsByRaiseHandOrder_noRaiseHand_bothOrdersShouldMatch() {
        let harness = Harness(call: CallEntity())
        XCTAssertTrue(harness.callParticipantsAndSortedParticipantsMustBeEqual())
    }
    
    func test_sortCallParticipantsByRaiseHandOrder_oneParticipantRaiseHand_shouldBeTheFirst() {
        let harness = Harness(call: CallEntity(raiseHandsList: [103]))
        XCTAssertTrue(harness.firstUserWithRaiseHandMustBeFirst())
    }
    
    func test_sortCallParticipantsByRaiseHandOrder_twoParticipantRaiseHand_shouldBeTheCorrectOrder() {
        let harness = Harness(call: CallEntity(raiseHandsList: [102, 101]))
        XCTAssertTrue(harness.sortedRaiseHandUsersMustMatchWithRaisedHandList())
    }
    
    class Harness {
        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2)
        let thirdParticipant = CallParticipantEntity(participantId: 103, clientId: 3)
        
        lazy var callParticipants = [firstParticipant, secondParticipant, thirdParticipant]
        
        let call: CallEntity
                
        init(
            call: CallEntity
        ) {
            self.call = call
        }
        
        func sut() -> [CallParticipantEntity] {
            return callParticipants.sortByRaiseHand(call: call)
        }
        
        func callParticipantsAndSortedParticipantsMustBeEqual() -> Bool {
            callParticipants == sut()
        }
        
        func firstUserWithRaiseHandMustBeFirst() -> Bool {
            sut().first?.participantId == call.raiseHandsList.first
        }
        
        func sortedRaiseHandUsersMustMatchWithRaisedHandList() -> Bool {
            sut() == [secondParticipant, firstParticipant, thirdParticipant]
        }
    }
}
