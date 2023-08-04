import Combine
@testable import MEGA
import MEGAPresentation
import MEGASDKRepoMock
import XCTest

final class ProfileViewModelTests: XCTestCase {
    
    var subscriptions = Set<AnyCancellable>()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    func testAction_onViewDidLoad_defaultValue() {
        let sut = makeSUT()
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        
        XCTAssertEqual(result, expectedSectionsWithPlan)
    }
    
    func testAction_onViewDidLoad_featureFlagIsNewUpgradeAccountPlanUIDisabled_defaultValue() {
        let sut = makeSUT(featureFlags: [.newUpgradeAccountPlanUI: false])
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        
        XCTAssertEqual(result, expectedSectionsWithPlan)
    }
    
    func testAction_onViewDidLoad_featureFlagIsNewUpgradeAccountPlanUIEnabled_defaultValue() {
        let sut = makeSUT(featureFlags: [.newUpgradeAccountPlanUI: true])
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        
        XCTAssertEqual(result, expectedSectionsWithoutPlan)
    }
    
    func testAction_onViewDidLoad_featureFlagIsNewUpgradeAccountPlanUIEnabled_businessAccount() {
        let sut = makeSUT(isMasterBusinessAccount: true, featureFlags: [.newUpgradeAccountPlanUI: true])
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        
        XCTAssertEqual(result, expectedSectionsWithPlan)
    }
    
    func testAction_onViewDidLoad_featureFlagIsNewUpgradeAccountPlanUIDisabled_businessAccount() {
        let sut = makeSUT(isMasterBusinessAccount: true, featureFlags: [.newUpgradeAccountPlanUI: false])
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        
        XCTAssertEqual(result, expectedSectionsWithPlan)
    }
    
    func testAction_onViewDidLoad_whenSmsIsAllowed() {
        // Arrange
        let sut = makeSUT(smsState: .optInAndUnblock)
        
        // Act
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        
        // Assert
        let expectedResult = ProfileViewModel.SectionCellDataSource(
            sectionOrder: [.profile, .security, .plan, .session],
            sectionRows: [
                .profile: [.changeName, .changePhoto, .changeEmail(isLoading: false), .changePassword(isLoading: false), .phoneNumber],
                .security: [.recoveryKey],
                .plan: [.upgrade],
                .session: [.logout]
            ])
        XCTAssertEqual(result, expectedResult)
    }
    
    func testAction_changeEmail_emailCellShouldBeLoading() {
        // Arrange
        let sut = makeSUT()
        sut.dispatch(.onViewDidLoad)
        
        let expectation = XCTestExpectation(description: "Expected change email cell to be loading in the profile section")
        
        var result: ProfileViewModel.SectionCellDataSource?
        sut.sectionCellsPublisher
            .dropFirst(1)
            .first()
            .sink { sectionDataSource in
                result = sectionDataSource
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        // Act
        sut.dispatch(.changeEmail)
        
        // Assert
        wait(for: [expectation], timeout: 3)
        
        XCTAssertTrue(
            result?.sectionRows[.profile]?
                .contains(where: { $0 == .changeEmail(isLoading: true)}) ?? false
        )
    }
    
    func testAction_changePasword_passwordCellShouldBeLoading() {
        // Arrange
        let sut = makeSUT()
        sut.dispatch(.onViewDidLoad)
        
        let expectation = XCTestExpectation(description: "Expected change password cell to be loading in the profile section")
        
        var result: ProfileViewModel.SectionCellDataSource?
        sut.sectionCellsPublisher
            .dropFirst(1)
            .first()
            .sink { sectionDataSource in
                result = sectionDataSource
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        // Act
        sut.dispatch(.changePassword)
        
        // Assert
        wait(for: [expectation], timeout: 1)
        
        XCTAssertTrue(
            result?.sectionRows[.profile]?
                .contains(where: { $0 == .changePassword(isLoading: true)}) ?? false
        )
    }
    
    func testAction_changeEmail_shouldPresentChangeControler() {
        // Arrange
        let sut = makeSUT()
        sut.dispatch(.onViewDidLoad)
        
        // Act & Assert
        test(viewModel: sut, actions: [ProfileAction.changeEmail], expectedCommands: [.changeProfile(requestedChangeType: .email, isTwoFactorAuthenticationEnabled: true)])
    }
    
    func testAction_changePasword_shouldPresentChangeControler() {
        // Arrange
        let sut = makeSUT()
        sut.dispatch(.onViewDidLoad)
        
        // Act & Assert
        test(viewModel: sut, actions: [ProfileAction.changePassword], expectedCommands: [.changeProfile(requestedChangeType: .password, isTwoFactorAuthenticationEnabled: true)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        email: String = "test@email.com",
        smsState: SMSState = .notAllowed,
        isMasterBusinessAccount: Bool = false,
        featureFlags: [FeatureFlagKey: Bool] = [:]
    ) -> ProfileViewModel {
        
        ProfileViewModel(
            sdk: MockSdk(isMasterBusinessAccount: isMasterBusinessAccount, smsState: smsState, myEmail: email),
            featureFlagProvider: MockFeatureFlagProvider(list: featureFlags)
        )
    }
    
    private func receivedSectionDataSource(
        from sut: ProfileViewModel,
        after action: ProfileAction
    ) -> ProfileViewModel.SectionCellDataSource? {
        
        let expectation = XCTestExpectation(description: "Expected default set of sections and cell states")
        var result: ProfileViewModel.SectionCellDataSource?
        sut.sectionCellsPublisher
            .first()
            .sink { sectionDataSource in
                result = sectionDataSource
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        // Act
        sut.dispatch(action)
        wait(for: [expectation], timeout: 1)
        return result
    }
    
    private var expectedSectionsWithPlan: ProfileViewModel.SectionCellDataSource {
        ProfileViewModel.SectionCellDataSource(
            sectionOrder: [.profile, .security, .plan, .session],
            sectionRows: [
                .profile: [.changeName, .changePhoto, .changeEmail(isLoading: false), .changePassword(isLoading: false)],
                .security: [.recoveryKey],
                .plan: [.upgrade],
                .session: [.logout]
            ])
    }
    
    private var expectedSectionsWithoutPlan: ProfileViewModel.SectionCellDataSource {
        ProfileViewModel.SectionCellDataSource(
            sectionOrder: [.profile, .security, .session],
            sectionRows: [
                .profile: [.changeName, .changePhoto, .changeEmail(isLoading: false), .changePassword(isLoading: false)],
                .security: [.recoveryKey],
                .session: [.logout]
            ])
    }
}
