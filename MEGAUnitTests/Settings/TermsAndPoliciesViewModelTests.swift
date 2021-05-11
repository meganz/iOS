import XCTest
@testable import MEGA

final class TermsAndPoliciesViewModelTests: XCTestCase {
    
    let mockRouter = MockTermsAndPoliciesRouter()
    
    func testAction_showPrivacyPolicy() {
        let vm = TermsAndPoliciesViewModel(router: mockRouter)
        test(viewModel: vm, action: .showPrivacyPolicy , expectedCommands: [])
        XCTAssertEqual(mockRouter.showPrivacyPolicy_calledTimes, 1)
    }
    
    func testAction_showCookiePolicy() {
        let vm = TermsAndPoliciesViewModel(router: mockRouter)
        test(viewModel: vm, action: .showCookiePolicy, expectedCommands: [])
        XCTAssertEqual(mockRouter.showCookiePolicy_calledTimes, 1)
    }
    
    func testAction_showTermsOfService() {
        let vm = TermsAndPoliciesViewModel(router: mockRouter)
        test(viewModel: vm, action: .showTermsOfService, expectedCommands: [])
        XCTAssertEqual(mockRouter.showTermsOfService_calledTimes, 1)
    }
    
}

final class MockTermsAndPoliciesRouter: TermsAndPoliciesRouterProtocol {
    var showPrivacyPolicy_calledTimes = 0
    var showCookiePolicy_calledTimes = 0
    var showTermsOfService_calledTimes = 0
    
    func didTap(on source: TermsAndPoliciesSource) {
        switch source {
        case .showPrivacyPolicy:
            showPrivacyPolicy_calledTimes += 1
            
        case .showCookiePolicy:
            showCookiePolicy_calledTimes += 1
            
        case .showTermsOfService:
            showTermsOfService_calledTimes += 1
        }
    }
}
