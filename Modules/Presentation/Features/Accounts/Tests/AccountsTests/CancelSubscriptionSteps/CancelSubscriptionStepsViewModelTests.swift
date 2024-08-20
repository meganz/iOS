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
    
    private func makeSUT(data: CancelSubscriptionData) -> CancelSubscriptionStepsViewModel {
        CancelSubscriptionStepsViewModel(helper: MockCancelSubscriptionStepsHelper(data: data))
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
        
        let sut = makeSUT(data: cancelSubscriptionData)

        await sut.setupStepList()

        XCTAssertEqual(sut.title, expectedTitle)
        XCTAssertEqual(sut.message, expectedMessage)
        XCTAssertEqual(sut.sections.count, 1)
        XCTAssertEqual(sut.sections.first?.title, expectedSection.title)
        XCTAssertEqual(sut.sections.first?.steps.count, 1)
        XCTAssertEqual(sut.sections.first?.steps.first?.text, expectedStep.text)
    }

    func testDismiss_shouldDismissReturnTrue() async {
        let sut = makeSUT(data: emptyData)
        let exp = expectation(description: "Should dismiss view")
        let shouldDismissSubscription = sut.$shouldDismiss
            .dropFirst()
            .sink { shouldDismiss in
                XCTAssertTrue(shouldDismiss)
                exp.fulfill()
            }
        
        await sut.dismiss()
        
        await fulfillment(of: [exp], timeout: 0.5)
        shouldDismissSubscription.cancel()
    }
}
