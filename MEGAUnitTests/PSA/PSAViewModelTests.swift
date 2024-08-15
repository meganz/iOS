@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class PSAViewModelTests: XCTestCase {
    
    @MainActor func testAction_onViewReady_fetchPSAEntity() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocPSAEntity())))
        let router = PSAViewRouter(tabBarController: UITabBarController())
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())
        test(viewModel: viewModel, action: .showPSAViewIfNeeded, expectedCommands: [])
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [.configView(mocPSAEntity())])
    }
    
    @MainActor func testAction_shouldShowPSAView_AfterOneHourScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocPSAEntity())))
        let router = MockPSAViewRouter()
        let mocPreferenceUseCase = MockPreferenceUseCase()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: mocPreferenceUseCase)
        mocPreferenceUseCase.dict[PreferenceKeyEntity.lastPSARequestTimestamp] = Date().timeIntervalSince1970 - 3600
        test(viewModel: viewModel, action: .showPSAViewIfNeeded, expectedCommands: [])
        XCTAssertTrue(router.psaViewShown)
    }
    
    @MainActor func testAction_shouldShowPSAView_WithinOneHourScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocPSAEntity())))
        let router = MockPSAViewRouter()
        let mocPreferenceUseCase = MockPreferenceUseCase()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: mocPreferenceUseCase)
        mocPreferenceUseCase.dict[PreferenceKeyEntity.lastPSARequestTimestamp] = Date().timeIntervalSince1970 - 3599
        test(viewModel: viewModel, action: .showPSAViewIfNeeded, expectedCommands: [])
        XCTAssertFalse(router.psaViewShown)
    }
    
    @MainActor func testAction_shouldShowPSAView_SuccessScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocPSAEntity())))
        let router = MockPSAViewRouter()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())

        test(viewModel: viewModel, action: .showPSAViewIfNeeded, expectedCommands: [])
        XCTAssertTrue(router.psaViewShown)
    }

    @MainActor func testAction_shouldShowPSAView_genericErrorScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .failure(.generic)))
        let router = MockPSAViewRouter()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())

        test(viewModel: viewModel, action: .showPSAViewIfNeeded, expectedCommands: [])
        XCTAssertFalse(router.psaViewShown)
    }

    @MainActor func testAction_shouldShowPSAView_noDataAvailableScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .failure(.noDataAvailable)))
        let router = MockPSAViewRouter()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())

        test(viewModel: viewModel, action: .showPSAViewIfNeeded, expectedCommands: [])
        XCTAssertFalse(router.psaViewShown)
    }

    @MainActor func testAction_shouldShowPSAView_PSAAlreadyShownScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocPSAEntity())))
        let mockPreference = MockPreferenceUseCase()
        mockPreference.dict[.lastPSARequestTimestamp] = Date().timeIntervalSince1970
        let router = MockPSAViewRouter()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: mockPreference)

        test(viewModel: viewModel, action: .showPSAViewIfNeeded, expectedCommands: [])
        XCTAssertFalse(router.psaViewShown)
    }

    @MainActor func testAction_shouldShowPSAView_PSAURLScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocURLPSAEntity())))
        let router = MockPSAViewRouter()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())

        test(viewModel: viewModel, action: .showPSAViewIfNeeded, expectedCommands: [])
        XCTAssertTrue(router.didOpenPSAURLString)
    }
    
    @MainActor func testAction_hidePSAViewScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocURLPSAEntity())))
        let router = MockPSAViewRouter()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())

        test(viewModel: viewModel, action: .setPSAViewHidden(true), expectedCommands: [])
        XCTAssertFalse(router.psaViewShown)
    }
    
    @MainActor func testAction_showPSAViewScenario() {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: .success(mocURLPSAEntity())))
        let router = MockPSAViewRouter()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: MockPreferenceUseCase())

        test(viewModel: viewModel, action: .setPSAViewHidden(false), expectedCommands: [])
        XCTAssertTrue(router.psaViewShown)
    }

    // MARK: - Private methods

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

final class MockPSAViewRouter: PSAViewRouting {
    
    var psaViewShown = false
    var didOpenPSAURLString = false
    
    func start() {
        psaViewShown = true
    }
    
    func currentPSAView() -> PSAView? {
        return nil
    }
    
    func isPSAViewAlreadyShown() -> Bool {
        return psaViewShown
    }
    
    func hidePSAView(_ hide: Bool) {
        psaViewShown = !hide
    }
    
    func openPSAURLString(_ urlString: String) {
        didOpenPSAURLString = true
    }
    
    func dismiss(psaView: PSAView) {
        psaViewShown = false
    }
    
}
