
import XCTest
@testable import MEGA

final class PSAViewModelTests: XCTestCase {
    
    func testAction_onViewReady_fetchPSAEntity() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocPSAEntity())))
        let router = PSAViewRouter(tabBarController: UITabBarController(), delegate: MockPSAViewRouterDelegate())
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [.configView(mocPSAEntity())])
    }
    
    func testAction_shouldShowPSAView_SuccessScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocPSAEntity())))
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
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .failure(.generic)))
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
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .failure(.noDataAvailable)))
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
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocPSAEntity())))
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
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocURLPSAEntity())))
        let router = PSAViewRouter(tabBarController: UITabBarController(), delegate: MockPSAViewRouterDelegate())
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())
        
        let showExpectation = expectation(description: "show psa view")

        viewModel.shouldShowView { show in
            XCTAssertFalse(show)
            showExpectation.fulfill()
        }
        
        wait(for: [showExpectation], timeout: 10)
    }
    
    //MARK:- Private methods
    
    private func mocPSAEntity() -> PSAEntity {
        return PSAEntity(identifier: 400,
                         title: "Terms of service update",
                         description: "Our revised Terms of service, Privacy and data policy, and taken down guidence policy apply from Jan 18th January 2021",
                         imageURL: "https://eu.static.mega.co.nz/3/images/mega/psa/psa1.png",
                         positiveText: "View Terms",
                         positiveLink: "https://mega.nz/updatedterms",
                         URLString: nil
        )
    }
    
    private func mocURLPSAEntity() -> PSAEntity {
        return PSAEntity(identifier: 400,
                         title: "Terms of service update",
                         description: "Our revised Terms of service, Privacy and data policy, and taken down guidence policy apply from Jan 18th January 2021",
                         imageURL: "https://eu.static.mega.co.nz/3/images/mega/psa/psa1.png",
                         positiveText: "View Terms",
                         positiveLink: "https://mega.nz/updatedterms",
                         URLString: "https://mega.nz/updatedterms"
        )
    }
}

final class MockPSAViewRouterDelegate: PSAViewRouterDelegate {
    func psaViewdismissed() {}
}
