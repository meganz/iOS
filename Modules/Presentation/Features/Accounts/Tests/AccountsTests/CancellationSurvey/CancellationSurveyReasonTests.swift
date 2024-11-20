@testable import Accounts
import MEGAL10n
import Testing

struct CancellationSurveyReasonTests {
    
    @Suite("CancellationSurveyReason init")
    struct CancellationSurveyReasonInit {
        @Test("CancellationSurveyReason should have correct values")
        func initializeACancellationSurveyReason() {
            let expectedRandomID: CancellationSurveyReason.ID = .allCases.randomElement() ?? .one
            let expectedTitle = "Test"
            let expectedFollowUpReasons = [
                CancellationSurveyFollowUpReason(
                    id: [.a, .b, .c].randomElement() ?? .a,
                    mainReasonID: expectedRandomID,
                    title: "Follow up reason"
                )
            ]
            
            let sut = CancellationSurveyReason(id: expectedRandomID, title: expectedTitle, followUpReasons: expectedFollowUpReasons)
            
            #expect(sut.id == expectedRandomID)
            #expect(sut.title == expectedTitle)
            #expect(sut.followUpReasons == expectedFollowUpReasons)
        }
    }
    
    @Suite("CancellationSurveyReason makeList")
    struct CancellationSurveyReasonListing {
        @Test("List should contain the same number of items as the available CancellationSurveyReason IDs")
        func makeListCount() {
            let list = CancellationSurveyReason.makeList()
            let expectedCount = CancellationSurveyReason.ID.allCases.count
            
            #expect(list.count == expectedCount)
        }
        
        @Test("List should contain reason ID one with correct follow up reasons")
        func reasonOneWithFollowUpReasons() throws {
            let expectedFollowUpReasons = [
                CancellationSurveyFollowUpReason(id: .a, mainReasonID: .one, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.One.a),
                CancellationSurveyFollowUpReason(id: .b, mainReasonID: .one, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.One.b),
                CancellationSurveyFollowUpReason(id: .c, mainReasonID: .one, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.One.c)
            ]
            let expectedReason = CancellationSurveyReason(
                id: .one,
                title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.one,
                followUpReasons: expectedFollowUpReasons
            )
            
            let list = CancellationSurveyReason.makeList()
            let reasonOne = try #require(list.first { $0.id == .one }, "Reason with follow up reason could not be found on the list")
            
            #expect(reasonOne.title == expectedReason.title)
            #expect(Set(reasonOne.followUpReasons) == Set(expectedFollowUpReasons))
        }
        
        @Test(
            "List should contain correct items without follow up reason",
            arguments: [
                CancellationSurveyReason(id: .two, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.two),
                CancellationSurveyReason(id: .three, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.three),
                CancellationSurveyReason(id: .four, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.four),
                CancellationSurveyReason(id: .five, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.five),
                CancellationSurveyReason(id: .six, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.six),
                CancellationSurveyReason(id: .seven, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.seven),
                CancellationSurveyReason(id: .eight, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.eight),
                CancellationSurveyReason(id: .nine, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.nine),
                CancellationSurveyReason(id: .ten, title: Strings.Localizable.Accounts.CancelSubscriptionSurvey.Reason.ten)
            ]
        )
        func makeListWithNoFollowUpReason(reason: CancellationSurveyReason) {
            let list = CancellationSurveyReason.makeList()
            
            #expect(list.contains(reason))
        }
    }
    
    @Suite("CancellationSurveyReason util methods")
    struct CancellationSurveyReasonUtil {
        @Test(
            "isOtherReason should only be true if ID is eight",
            arguments: [
                (CancellationSurveyReason(id: .one, title: "Reason one"), false),
                (CancellationSurveyReason(id: .two, title: "Reason two"), false),
                (CancellationSurveyReason(id: .eight, title: "Reason eight"), true)
            ]
        )
        func isOtherReason(reason: CancellationSurveyReason, expectedResult: Bool) {
            #expect(reason.isOtherReason == expectedResult)
        }
        
        @Test("otherReasonID should return ID eight")
        func otherReasonID() {
            #expect(CancellationSurveyReason.otherReasonID == .eight)
        }
    }
}
