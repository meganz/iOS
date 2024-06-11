@testable import Accounts
import AccountsMock
import XCTest

final class CancelSubscriptionStepsViewModelTests: XCTestCase {
    private var emptyData: CancelSubscriptionData {
        CancelSubscriptionData(
            title: "",
            message: "",
            sections: []
        )
    }
    
    private func makeSUT(data: CancelSubscriptionData) -> (CancelSubscriptionStepsViewModel, MockCancelSubscriptionStepsRouter) {
        let router = MockCancelSubscriptionStepsRouter()
        
        let sut = CancelSubscriptionStepsViewModel(
            helper: MockCancelSubscriptionStepsHelper(data: data),
            router: router
        )
        
        return (sut, router)
    }

    func testSetupStepList_setsCorrectData() async {
        let expectedTitle = "Test Title"
        let expectedMessage = "Test Message"
        let expectedStep = Step(text: "Step 1")
        let expectedSection = StepSection(title: "Test Section", steps: [expectedStep])
        let cancelSubscriptionData = CancelSubscriptionData(
            title: expectedTitle,
            message: expectedMessage,
            sections: [expectedSection]
        )
        
        let (sut, _) = makeSUT(data: cancelSubscriptionData)

        await sut.setupStepList()

        XCTAssertEqual(sut.title, expectedTitle)
        XCTAssertEqual(sut.message, expectedMessage)
        XCTAssertEqual(sut.sections.count, 1)
        XCTAssertEqual(sut.sections.first?.title, expectedSection.title)
        XCTAssertEqual(sut.sections.first?.steps.count, 1)
        XCTAssertEqual(sut.sections.first?.steps.first?.text, expectedStep.text)
    }

    func testDismiss_callsRouterDismiss() {
        let (sut, router) = makeSUT(data: emptyData)

        sut.dismiss()

        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
}
