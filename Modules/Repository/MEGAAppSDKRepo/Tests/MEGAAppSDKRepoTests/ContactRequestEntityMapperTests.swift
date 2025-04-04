import MEGAAppSDKRepoMock
import MEGASdk
import XCTest

final class ContactRequestEntityMapperTests: XCTestCase {
    
    func testContactRequest_shouldMapToContactRequestEntity() async {
        let isOutgoing = Bool.random()
        let status = MEGAContactRequestStatus(rawValue: UInt.random(in: 0...5)) ?? .unresolved
        let mockContactRequest = MockContactRequest(handle: 1,
                                                    sourceEmail: "test@mega.co.nz",
                                                    sourceMessage: "For testing",
                                                    targetEmail: "test1@mega.co.nz",
                                                    creationTime: Date(),
                                                    modificationTime: Date(),
                                                    isOutgoing: isOutgoing,
                                                    status: status)
        let entity = mockContactRequest.toContactRequestEntity()
        XCTAssertEqual(mockContactRequest.handle, entity.handle)
        XCTAssertEqual(mockContactRequest.sourceEmail, entity.sourceEmail)
        XCTAssertEqual(mockContactRequest.sourceMessage, entity.sourceMessage)
        XCTAssertEqual(mockContactRequest.targetEmail, entity.targetEmail)
        XCTAssertEqual(mockContactRequest.creationTime, entity.creationTime)
        XCTAssertEqual(mockContactRequest.modificationTime, entity.modificationTime)
        XCTAssertEqual(mockContactRequest.isOutgoing(), entity.isOutgoing)
        XCTAssertEqual(mockContactRequest.status.toContactRequestStatus(), entity.status)
    }
    
    func testContactRequest_mapToContactRequestEntity_countShouldMatch() {
        let contactRequestList = MockContactRequestList()
        let contactRequestEntities = contactRequestList.toContactRequestEntities()
        
        XCTAssertEqual(contactRequestEntities.count, 0)
    }

}
