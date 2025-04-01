import Chat
import MEGADomain
import MEGASwiftUI
import XCTest

final class RaiseHandUpdaterTests: XCTestCase {
    class Harness {
        class MockSnackBarProvider: RaiseHandSnackBarProviding {
            var snackBarToReturn: SnackBar?
            var insertedParticipants: [CallParticipantEntity]?
            var insertedLocalRaisedHand: Bool?
            func snackBar(
                participantsThatJustRaisedHands: [CallParticipantEntity],
                localRaisedHand: Bool
            ) -> SnackBar? {
                insertedParticipants = participantsThatJustRaisedHands
                insertedLocalRaisedHand = localRaisedHand
                return snackBarToReturn
            }
        }
        let factory = MockSnackBarProvider()
        
        lazy var sut = RaiseHandUpdater(
            snackBarFactory: factory,
            updateLocalRaiseHand: updateLocalRaiseHand,
            stateUpdater: stateUpdater,
            snackBarUpdater: snackBarUpdater
        )
        
        init() {
            
        }
        
        var updateLocalRaiseHandReceived: [Bool] = []
        private func updateLocalRaiseHand(_ hidden: Bool) {
            updateLocalRaiseHandReceived.append(hidden)
        }
        
        struct StateUpdates: Equatable {
            init(
                _ index: Int,
                _ change: RaiseHandDiffing.Change
            ) {
                self.index = index
                self.change = change
            }
            
            var index: Int
            var change: RaiseHandDiffing.Change
            
        }
        
        var stateUpdates: [StateUpdates] = []
        private func stateUpdater(_ index: Int, _ change: RaiseHandDiffing.Change) {
            stateUpdates.append(.init(index, change))
        }
        var snackBarsReceived: [SnackBar?] = []
        private func snackBarUpdater(_ snackBar: SnackBar?) {
            snackBarsReceived.append(snackBar)
        }
        
        func update(
            before: [HandleEntity],
            after: [HandleEntity]
        ) {
            sut.update(
                callParticipants: .testParticipants,
                raiseHandListBefore: before,
                raiseHandListAfter: after,
                localUserHandle: .localUserHandle
            )
        }
        
        func oneRemoteRaisedHand() {
            update(before: [], after: [1 /*this participant has index 0 in testParticipants array*/])
        }
        
        func oneRemoteLoweredHand() {
            update(before: [1], after: [])
        }
        
        func localRaised() {
            update(before: [], after: [.localUserHandle])
        }
        
        func localLowered() {
            update(before: [.localUserHandle], after: [])
        }
        
        func localAndRemoteRaised() {
            update(before: [], after: [1, .localUserHandle])
        }
    }
    
    func testUpdate_OneRemoteRaised_UpdateStateAtIndex0() {
        let harness = Harness()
        harness.oneRemoteRaisedHand()
        let firstRaisedHand = RaiseHandDiffing.Change(handle: 1, raisedHand: true, index: 0)
        XCTAssertEqual(harness.stateUpdates, [.init(0, firstRaisedHand)])
        XCTAssertEqual(harness.updateLocalRaiseHandReceived, [true])
    }
    
    func testUpdate_OneRemoteRaised_ShowsSnackBar() {
        let harness = Harness()
        harness.factory.snackBarToReturn = .testSnackBar
        harness.oneRemoteRaisedHand()
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, false)
        XCTAssertEqual(harness.factory.insertedParticipants, [.testParticipant(participantId: 1)])
        XCTAssertEqual(harness.snackBarsReceived, [.testSnackBar])
    }
    
    func testUpdate_OneRemoteLowered_UpdateStateAtIndex0() {
        let harness = Harness()
        harness.oneRemoteLoweredHand()
        let firstRaisedHand = RaiseHandDiffing.Change(handle: 1, raisedHand: false, index: 0)
        XCTAssertEqual(harness.stateUpdates, [.init(0, firstRaisedHand)])
        XCTAssertEqual(harness.updateLocalRaiseHandReceived, [true])
    }
    
    func testUpdate_OneRemoteLowered_HidesSnackBar() {
        let harness = Harness()
        harness.factory.snackBarToReturn = nil
        harness.oneRemoteLoweredHand()
        // factory should receive : nobody has raised hand -> nil snack bar will be returned
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, false)
        XCTAssertEqual(harness.factory.insertedParticipants, [])
        XCTAssertEqual(harness.snackBarsReceived, [nil])
    }
    
    func testUpdate_LocalRaised_UpdateState() {
        let harness = Harness()
        harness.localRaised()
        XCTAssertEqual(harness.stateUpdates, [])
        XCTAssertEqual(harness.updateLocalRaiseHandReceived, [false])
    }
    
    func testUpdate_LocalLowered_SnackBarUpdated() {
        let harness = Harness()
        harness.factory.snackBarToReturn = .testSnackBar
        harness.localRaised()
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, true)
        XCTAssertEqual(harness.factory.insertedParticipants, [])
        XCTAssertEqual(harness.snackBarsReceived, [.testSnackBar])
    }
    
    func testUpdate_LocalLowered_UpdateState() {
        let harness = Harness()
        harness.localLowered()
        XCTAssertEqual(harness.stateUpdates, [])
        XCTAssertEqual(harness.updateLocalRaiseHandReceived, [true])
    }
    
    func testUpdate_LocalLowered_HidesSnackBar() {
        let harness = Harness()
        harness.factory.snackBarToReturn = nil
        harness.localLowered()
        // factory should receive : nobody has raised hand -> nil snack bar will be returned
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, false)
        XCTAssertEqual(harness.factory.insertedParticipants, [])
        XCTAssertEqual(harness.snackBarsReceived, [nil])
    }
    
    func testUpdate_LocalAndRemoteRaised_UpdateState() {
        let harness = Harness()
        harness.localAndRemoteRaised()
        let firstRaisedHand = RaiseHandDiffing.Change(handle: 1, raisedHand: true, index: 0)
        XCTAssertEqual(harness.stateUpdates, [.init(0, firstRaisedHand)])
        XCTAssertEqual(harness.updateLocalRaiseHandReceived, [false]) // update local camera feed
    }
    
    func testUpdate_LocalAndRemoteRaised_SnackBarUpdated() {
        let harness = Harness()
        harness.factory.snackBarToReturn = .testSnackBar
        harness.localAndRemoteRaised()
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, true)
        XCTAssertEqual(harness.factory.insertedParticipants, [.testParticipant(participantId: 1)])
        XCTAssertEqual(harness.snackBarsReceived, [.testSnackBar])
    }
    
    func testLocalUserRaisedFromDifferentClient_OnlySingleUserInMeeting_FactoryGetsOnlyLocalUser() {
        let harness = Harness()
        
        // As a user, I'm only one in the meeting but I joined from two clients
        // and I do not want to see 'You and 1 other raised hand"
        // but I want to see You raised your hand"
        // so factory should have empty array of participants with raised hand
        // true as local user raised hand
        harness.sut.update(
            callParticipants: [
                .testParticipant(participantId: .localUserHandle)
            ],
            raiseHandListBefore: [],
            raiseHandListAfter: [.localUserHandle],
            localUserHandle: .localUserHandle
        )
        
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, true)
        XCTAssertEqual(harness.factory.insertedParticipants, [])
    }
    
    func testLocalUserRaisedFromManyDifferentClient_OnlySingleUserInMeeting_FactoryGetsOnlyLocalUser() {
        let harness = Harness()
        harness.sut.update(
            callParticipants: [
                .testParticipant(participantId: .localUserHandle),
                .testParticipant(participantId: .localUserHandle),
                .testParticipant(participantId: .localUserHandle)
            ],
            raiseHandListBefore: [],
            raiseHandListAfter: [.localUserHandle],
            localUserHandle: .localUserHandle
        )
        
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, true)
        XCTAssertEqual(harness.factory.insertedParticipants, [])
    }
    
    func testLocalUserRaisedFromDifferentClient_MoreUsersInMeeting_FactoryGetsOnlyLocalUser() {
        let harness = Harness()
        harness.sut.update(
            callParticipants: [
                .testParticipant(participantId: .localUserHandle),
                .testParticipant(participantId: 2),
                .testParticipant(participantId: 3)
            ],
            raiseHandListBefore: [],
            raiseHandListAfter: [.localUserHandle],
            localUserHandle: .localUserHandle
        )
        
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, true)
        XCTAssertEqual(harness.factory.insertedParticipants, [])
    }
    
    func testLocalUserLoweredFromDifferentClient_SingleUserInMeeting_FactoryGetsOnlyLocalUserFalse() {
        let harness = Harness()
        harness.sut.update(
            callParticipants: [
                .testParticipant(participantId: .localUserHandle)
            ],
            raiseHandListBefore: [.localUserHandle],
            raiseHandListAfter: [],
            localUserHandle: .localUserHandle
        )
        
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, false)
        XCTAssertEqual(harness.factory.insertedParticipants, [])
    }
    
    func testLocalUserHasRaisedHand_JoinedFromTwoClients_OtherUserRaises() {
        let harness = Harness()
        harness.sut.update(
            callParticipants: [
                .testParticipant(participantId: .localUserHandle),
                .testParticipant(participantId: 1)
            ],
            raiseHandListBefore: [.localUserHandle],
            raiseHandListAfter: [1, .localUserHandle],
            localUserHandle: .localUserHandle
        )
        
        XCTAssertEqual(harness.factory.insertedLocalRaisedHand, false)
        XCTAssertEqual(harness.factory.insertedParticipants, [.testParticipant(participantId: 1)])
    }
}

extension HandleEntity {
    static let localUserHandle: HandleEntity = 4
}

extension [CallParticipantEntity] {
    static var testParticipants: Self {
        [
            .testParticipant(participantId: 1),
            .testParticipant(participantId: 2),
            .testParticipant(participantId: 3)
        ]
    }
}

extension SnackBar? {
    static var testSnackBar: SnackBar {
        SnackBar(
            message: "M",
            layout: .horizontal,
            action: nil,
            colors: .default
        )
    }
}

extension CallParticipantEntity {
    static var testParticipant: Self {
        .testParticipant()
    }
    
    static func testParticipant(
        chatId: HandleEntity = 100,
        participantId: HandleEntity = 100,
        clientId: HandleEntity = 100
    ) -> Self {
        .init(
            chatId: chatId,
            participantId: participantId,
            clientId: clientId,
            isModerator: false,
            canReceiveVideoHiRes: true
        )
    }
}
