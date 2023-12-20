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
        
        let expectedSections = ProfileViewModel.SectionCellDataSource(
            sectionOrder: [.profile, .security, .session],
            sectionRows: [
                .profile: [.changeName, .changePhoto, .changeEmail(isLoading: false), .changePassword(isLoading: false)],
                .security: [.recoveryKey],
                .session: [.logout]
            ])
        XCTAssertEqual(result, expectedSections)
    }
    
    func testAction_onViewDidLoad_whenSmsIsAllowed() {
        let sut = makeSUT(smsState: .optInAndUnblock)
        
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        
        let expectedResult = ProfileViewModel.SectionCellDataSource(
            sectionOrder: [.profile, .security, .session],
            sectionRows: [
                .profile: [.changeName, .changePhoto, .changeEmail(isLoading: false), .changePassword(isLoading: false), .phoneNumber],
                .security: [.recoveryKey],
                .session: [.logout]
            ])
        XCTAssertEqual(result, expectedResult)
    }
    
    func testAction_changeEmail_emailCellShouldBeLoading() {
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

        sut.dispatch(.changeEmail)
        
        wait(for: [expectation], timeout: 3)
        
        XCTAssertTrue(
            result?.sectionRows[.profile]?
                .contains(where: { $0 == .changeEmail(isLoading: true)}) ?? false
        )
    }
    
    func testAction_changePasword_passwordCellShouldBeLoading() {
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
        
        sut.dispatch(.changePassword)
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertTrue(
            result?.sectionRows[.profile]?
                .contains(where: { $0 == .changePassword(isLoading: true)}) ?? false
        )
    }
    
    func testAction_changeEmail_shouldPresentChangeControler() {
        let sut = makeSUT()
        sut.dispatch(.onViewDidLoad)
        
        test(viewModel: sut, actions: [ProfileAction.changeEmail], expectedCommands: [.changeProfile(requestedChangeType: .email, isTwoFactorAuthenticationEnabled: true)])
    }
    
    func testAction_changePasword_shouldPresentChangeControler() {
        let sut = makeSUT()
        sut.dispatch(.onViewDidLoad)
        
        test(viewModel: sut, actions: [ProfileAction.changePassword], expectedCommands: [.changeProfile(requestedChangeType: .password, isTwoFactorAuthenticationEnabled: true)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        email: String = "test@email.com",
        smsState: SMSState = .notAllowed,
        isMasterBusinessAccount: Bool = false
    ) -> ProfileViewModel {
        
        ProfileViewModel(
            sdk: MockSdk(isMasterBusinessAccount: isMasterBusinessAccount, smsState: smsState, myEmail: email)
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
        
        sut.dispatch(action)
        wait(for: [expectation], timeout: 1)
        return result
    }
}
