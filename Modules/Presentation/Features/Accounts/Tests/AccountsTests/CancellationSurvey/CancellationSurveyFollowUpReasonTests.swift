@testable import Accounts
import Testing

struct CancellationSurveyFollowUpReasonTests {
    // MARK: - Helper
    private static var randomMainReasonID: CancellationSurveyReason.ID {
        .allCases.randomElement() ?? .one
    }
    
    // MARK: - Tests
    @Suite("CancellationSurveyFollowUpReason init")
    struct CancellationSurveyFollowUpReasonInit {
        @Test("CancellationSurveyFollowUpReason should have correct values")
        func initializeACancellationSurveyFollowUpReason() {
            let expectedRandomId: CancellationSurveyFollowUpReason.ID = [.a, .b, .c].randomElement() ?? .a
            let expectedMainReasonID = randomMainReasonID
            let expectedTitle = "Follow up reason"
            
            let sut = CancellationSurveyFollowUpReason(
                id: expectedRandomId,
                mainReasonID: expectedMainReasonID,
                title: expectedTitle
            )
            
            #expect(sut.id == expectedRandomId)
            #expect(sut.title == expectedTitle)
        }
    }
    
    @Suite("CancellationSurveyFollowUpReason util methods")
    struct CancellationSurveyFollowUpReasonUtil {
        @Test(
            "formattedID should have correct format of [MainReasonId].[FollowUpID]. ex. 1.a, 1.b, 1.c",
            arguments: [
                CancellationSurveyFollowUpReason(id: .a, mainReasonID: randomMainReasonID, title: "Reason A"),
                CancellationSurveyFollowUpReason(id: .b, mainReasonID: randomMainReasonID, title: "Reason B"),
                CancellationSurveyFollowUpReason(id: .c, mainReasonID: randomMainReasonID, title: "Reason C")
            ]
        )
        func formattedID(reason: CancellationSurveyFollowUpReason) {
            let expectedFormat = String(reason.mainReasonID.rawValue) + "." + reason.id.rawValue
            #expect(reason.formattedID == expectedFormat)
        }
    }
}
