import Chat
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwiftUI
import XCTest

final class RaiseHandSnackBarFactoryTests: XCTestCase {
    class Harness {
        var participants: [CallParticipantEntity]
        var localRaisedHand: Bool
        
        convenience init(
            raisedHands: Int,
            localRaisedHand: Bool = false
        ) {
            var array = [CallParticipantEntity]()
            for i in 0..<raisedHands {
                array.append(
                    .init(name: "Name\(i)", raisedHand: true)
                )
            }
            self.init(
                participants: array,
                localRaisedHand: localRaisedHand
            )
        }
        
        let sut: RaiseHandSnackBarFactory
        var viewRaisedHandsHandlerCallCount = 0
        var lowerHandHandlerCallCount = 0
        
        init(
            participants: [CallParticipantEntity] = [],
            localRaisedHand: Bool = false
        ) {
            self.participants = participants
            self.localRaisedHand = localRaisedHand
            var viewRaisedHandsHandler: () -> Void = {}
            var lowerHandHandler: () -> Void = {}
            
            sut = RaiseHandSnackBarFactory(
                viewRaisedHandsHandler: {
                    viewRaisedHandsHandler()
                },
                lowerHandHandler: {
                    lowerHandHandler()
                }
            )
            
            viewRaisedHandsHandler = { [unowned self] in
                self.viewRaisedHandsHandlerCallCount += 1
            }
            
            lowerHandHandler = { [unowned self] in
                self.lowerHandHandlerCallCount += 1
            }
        }
        
        var result: SnackBar? {
            sut.snackBar(
                participantsThatJustRaisedHands: participants,
                localRaisedHand: localRaisedHand
            )
        }
        
        static func expected(_ message: String, _ action: String) -> SnackBar? {
            SnackBar.raiseHandSnackBar(
                message: message,
                action: .init(
                    title: action,
                    handler: {}
                )
            )
        }
        
        func actionCalled() -> Self {
            let result = self.result
            result?.action?.handler()
            return self
        }
        
        static func expectedManyOthers(_ name: String, _ count: Int, _ action: String) -> SnackBar? {
            let string = Strings.Localizable.Chat.Call.RaiseHands.SnackBar.manyOtherPersonsRaisedHands(count)
            return expected(string.replacingOccurrences(of: "[A]", with: name), action)
        }
    }
    
    func testNoHandRaised_ReturnsNil() {
        let result = Harness().result
        XCTAssertNil(result)
    }
    
    func testLocalUserRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(localRaisedHand: true).result
        let expected = Harness.expected(
            Strings.Localizable.Chat.Call.RaiseHand.SnackBar.ownUserRaisedHand,
            Strings.Localizable.Chat.Call.RaiseHand.SnackBar.lowerHand
        )
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testOtherOneRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(raisedHands: 1).result
        let expected = Harness.expected(
            Strings.Localizable.Chat.Call.RaiseHand.SnackBar.otherPersonRaisedHand("Name0"),
            Strings.Localizable.Chat.Call.RaiseHand.SnackBar.view
        )
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testMeAndOtherOneRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(raisedHands: 1, localRaisedHand: true).result
        let expected = Harness.expected(
            Strings.Localizable.Chat.Call.RaiseHands.SnackBar.youAndOtherPersonRaisedHands(1),
            Strings.Localizable.Chat.Call.RaiseHand.SnackBar.lowerHand
        )
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testMeAndManyOtherOneRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(raisedHands: 123, localRaisedHand: true).result
        let expected = Harness.expected(
            Strings.Localizable.Chat.Call.RaiseHands.SnackBar.youAndOtherPersonRaisedHands(123),
            Strings.Localizable.Chat.Call.RaiseHand.SnackBar.lowerHand
        )
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testManyOthersRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(raisedHands: 3).result
        let expected = Harness.expectedManyOthers("Name0", 2, Strings.Localizable.Chat.Call.RaiseHand.SnackBar.view)
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testManyOthersRaisedHand_SnackBarConfiguredProperly_TwoTotal() {
        let result = Harness(raisedHands: 2).result
        let expected = Harness.expectedManyOthers("Name0", 1, Strings.Localizable.Chat.Call.RaiseHand.SnackBar.view)
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testManyOthersRaisedHand_SnackBarConfiguredProperly_OnlyCountsRaisedHand() {
        let result = Harness(
            participants: [
                .init(name: "Bob1", raisedHand: false),
                .init(name: "Bob2", raisedHand: false),
                .init(name: "Bob3", raisedHand: false),
                .init(name: "Bob4", raisedHand: true),
                .init(name: "Bob5", raisedHand: true)
            ]
        ).result
        let expected = Harness.expectedManyOthers("Bob4", 1, Strings.Localizable.Chat.Call.RaiseHand.SnackBar.view)
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testViewAction_WhenTriggered_ClosureCalled() {
        let harness = Harness(raisedHands: 1, localRaisedHand: false).actionCalled()
        XCTAssertEqual(harness.viewRaisedHandsHandlerCallCount, 1)
        XCTAssertEqual(harness.lowerHandHandlerCallCount, 0)
    }
    
    func testLowerHandAction_WhenTrigger_ClosureCalled() {
        let harness = Harness(localRaisedHand: true).actionCalled()
        XCTAssertEqual(harness.lowerHandHandlerCallCount, 1)
        XCTAssertEqual(harness.viewRaisedHandsHandlerCallCount, 0)
    }
}
