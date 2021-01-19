
import XCTest
@testable import MEGA

final class PSAViewModelTests: XCTestCase {
    
    func testAction_onViewReady_fetchPSAEntity() {
        let useCase = PSAUseCase(repo: MockPSARepository(mockOption: .successPSAEntity))
        let router = PSAViewRouter(tabBarController: UITabBarController(), delegate: MockPSAViewRouterDelegate())
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [.configView(PSAEntity.mocPSAEntity())])
    }
    
    func testAction_shouldShowPSAView_SuccessScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(mockOption: .successPSAEntity))
        let router = PSAViewRouter(tabBarController: UITabBarController(), delegate: MockPSAViewRouterDelegate())
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())
        
        let showExpectation = expectation(description: "show psa view")

        viewModel.shouldShowView { show in
            XCTAssert(show)
            showExpectation.fulfill()
        }
        
        wait(for: [showExpectation], timeout: 10)
    }
    
    func testAction_shouldShowPSAView_genericErrorScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(mockOption: .genericError))
        let router = PSAViewRouter(tabBarController: UITabBarController(), delegate: MockPSAViewRouterDelegate())
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())
        
        let showExpectation = expectation(description: "show psa view")

        viewModel.shouldShowView { show in
            XCTAssertFalse(show)
            showExpectation.fulfill()
        }
        
        wait(for: [showExpectation], timeout: 10)
    }
    
    func testAction_shouldShowPSAView_noDataAvailableScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(mockOption: .noDataAvailable))
        let router = PSAViewRouter(tabBarController: UITabBarController(), delegate: MockPSAViewRouterDelegate())
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())
        
        let showExpectation = expectation(description: "show psa view")

        viewModel.shouldShowView { show in
            XCTAssertFalse(show)
            showExpectation.fulfill()
        }
        
        wait(for: [showExpectation], timeout: 10)
    }
    
    func testAction_shouldShowPSAView_PSAAlreadyShownScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(mockOption: .successPSAEntity))
        let mockPreference = MockPreferenceUseCase()
        mockPreference.dict[.lastPSAShownTimestamp] = Date().timeIntervalSince1970
        let router = PSAViewRouter(tabBarController: UITabBarController(), delegate: MockPSAViewRouterDelegate())
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: mockPreference)
        
        let showExpectation = expectation(description: "show psa view")

        viewModel.shouldShowView { show in
            XCTAssertFalse(show)
            showExpectation.fulfill()
        }
        
        wait(for: [showExpectation], timeout: 10)
    }

    func testAction_shouldShowPSAView_PSAURLScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(mockOption: .successURLPSAEntity))
        let router = PSAViewRouter(tabBarController: UITabBarController(), delegate: MockPSAViewRouterDelegate())
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())
        
        let showExpectation = expectation(description: "show psa view")

        viewModel.shouldShowView { show in
            XCTAssertFalse(show)
            showExpectation.fulfill()
        }
        
        wait(for: [showExpectation], timeout: 10)
    }
}
