@testable import MEGA
import MEGADomain
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
                participants: participants,
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
    }
    
    func testNoHandRaised_ReturnsNil() {
        let result = Harness().result
        XCTAssertNil(result)
    }
    
    func testLocalUserRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(localRaisedHand: true).result
        let expected = Harness.expected("You raised your hand", "Lower hand")
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testOtherOneRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(raisedHands: 1).result
        let expected = Harness.expected("Name0 raised their hand", "View")
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testMeAndOtherOneRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(raisedHands: 1, localRaisedHand: true).result
        let expected = Harness.expected("You and 1 other raised their hands", "View")
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testMeAndManyOtherOneRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(raisedHands: 123, localRaisedHand: true).result
        let expected = Harness.expected("You and 123 others raised their hands", "View")
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testManyOthersRaisedHand_SnackBarConfiguredProperly() {
        let result = Harness(raisedHands: 3).result
        let expected = Harness.expected("Name0 and 2 others raised hand", "View")
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testManyOthersRaisedHand_SnackBarConfiguredProperly_TwoTotal() {
        let result = Harness(raisedHands: 2).result
        let expected = Harness.expected("Name0 and 1 other raised hand", "View")
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
        let expected = Harness.expected("Bob4 and 1 other raised hand", "View")
        XCTAssertSnackBarEqual(result, expected)
    }
    
    func testViewAction_WhenTrigger_ClosureCalled() {
        let harness = Harness(raisedHands: 1, localRaisedHand: true).actionCalled()
        XCTAssertEqual(harness.viewRaisedHandsHandlerCallCount, 1)
        XCTAssertEqual(harness.lowerHandHandlerCallCount, 0)
    }
    
    func testLowerHandAction_WhenTrigger_ClosureCalled() {
        let harness = Harness(localRaisedHand: true).actionCalled()
        XCTAssertEqual(harness.lowerHandHandlerCallCount, 1)
        XCTAssertEqual(harness.viewRaisedHandsHandlerCallCount, 0)
    }
}
