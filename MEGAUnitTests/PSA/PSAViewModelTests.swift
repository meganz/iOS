@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPreference
import XCTest

final class PSAViewModelTests: XCTestCase {
    private let urlString = "https://mega.nz/updatedterms"
    
    @MainActor func testAction_onViewReady_fetchPSAEntity() async {
        let (viewModel, router, _) = makeSUT(psaResult: .success(mockPSAEntity()))
        
        await test(viewModel: viewModel, action: .showPSAViewIfNeeded, expectedCommands: [])
        await test(viewModel: viewModel, action: .onViewReady, expectedCommands: [.configView(mockPSAEntity())])
        
        XCTAssertTrue(router.psaViewShown)
    }
    
    @MainActor func testAction_shouldShowPSAView_AfterOneHourScenario() async throws {
        await performTest(
            psaResult: .success(mockPSAEntity()),
            lastPSARequestTimestamp: Date().timeIntervalSince1970 - 3600,
            action: .showPSAViewIfNeeded,
            psaViewShown: true
        )
    }
    
    @MainActor func testAction_shouldShowPSAView_WithinOneHourScenario() async throws {
        await performTest(
            psaResult: .success(mockPSAEntity()),
            lastPSARequestTimestamp: Date().timeIntervalSince1970 - 3599,
            action: .showPSAViewIfNeeded,
            psaViewShown: false
        )
    }
    
    @MainActor func testAction_shouldShowPSAView_SuccessScenario() async throws {
        await performTest(
            psaResult: .success(mockPSAEntity()),
            action: .showPSAViewIfNeeded,
            psaViewShown: true
        )
    }
    
    @MainActor func testAction_shouldShowPSAView_genericErrorScenario() async throws {
        await performTest(
            psaResult: .failure(.generic),
            action: .showPSAViewIfNeeded,
            psaViewShown: false
        )
    }
    
    @MainActor func testAction_shouldShowPSAView_noDataAvailableScenario() async throws {
        await performTest(
            psaResult: .failure(.noDataAvailable),
            action: .showPSAViewIfNeeded,
            psaViewShown: false
        )
    }
    
    @MainActor func testAction_shouldShowPSAView_PSAAlreadyShownScenario() async throws {
        await performTest(
            psaResult: .success(mockPSAEntity()),
            lastPSARequestTimestamp: Date().timeIntervalSince1970,
            action: .showPSAViewIfNeeded,
            psaViewShown: false
        )
    }
    
    @MainActor func testAction_shouldShowPSAView_PSAURLScenario() async throws {
        await performTest(
            psaResult: .success(mockPSAEntity(url: urlString)),
            action: .showPSAViewIfNeeded,
            didOpenPSAURLString: true
        )
    }
    
    @MainActor func testAction_hidePSAViewScenario() async throws {
        await performTest(
            psaResult: .success(mockPSAEntity(url: urlString)),
            action: .setPSAViewHidden(true),
            psaViewShown: false
        )
    }
    
    @MainActor func testAction_showPSAViewScenario() async {
        await performTest(
            psaResult: .success(mockPSAEntity(url: urlString)),
            action: .setPSAViewHidden(false),
            psaViewShown: true
        )
    }
    
    // MARK: - Private helper methods
    
    @MainActor
    private func makeSUT(psaResult: Result<PSAEntity, PSAErrorEntity>) -> (PSAViewModel, MockPSAViewRouter, MockPreferenceUseCase) {
        let useCase = PSAUseCase(repo: MockPSARepository(psaResult: psaResult))
        let router = MockPSAViewRouter()
        let mockPreference = MockPreferenceUseCase()
        let viewModel = PSAViewModel(router: router, useCase: useCase, preferenceUseCase: mockPreference)
        return (viewModel, router, mockPreference)
    }
    
    @MainActor private func performTest(
        psaResult: Result<PSAEntity, PSAErrorEntity>,
        lastPSARequestTimestamp: TimeInterval? = nil,
        action: PSAViewAction,
        expectedCommands: [PSAViewModel.Command] = [],
        psaViewShown: Bool = false,
        didOpenPSAURLString: Bool = false
    ) async {
        let (viewModel, router, mockPreference) = makeSUT(psaResult: psaResult)
        
        if let timestamp = lastPSARequestTimestamp {
            mockPreference.dict[PreferenceKeyEntity.lastPSARequestTimestamp.rawValue] = timestamp
        }
        
        await test(viewModel: viewModel, action: action, expectedCommands: expectedCommands)
        await viewModel.currentTask?.value
        
        XCTAssertEqual(router.psaViewShown, psaViewShown)
        XCTAssertEqual(router.didOpenPSAURLString, didOpenPSAURLString)
    }
    
    private func mockPSAEntity(url: String? = nil) -> PSAEntity {
        PSAEntity(
            identifier: 400,
            title: "Terms of service update",
            description: "Our revised Terms of service, Privacy and data policy, and taken down guidance policy apply from Jan 18th January 2021",
            imageURL: "https://eu.static.mega.co.nz/3/images/mega/psa/psa1.png",
            positiveText: "View Terms",
            positiveLink: "https://mega.nz/updatedterms",
            URLString: url
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
