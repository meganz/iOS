import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
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
            sectionOrder: sectionsOrder(),
            sectionRows: sectionRows())
        
        XCTAssertEqual(result, expectedSections)
    }
    
    func testAction_onViewDidLoad_whenSmsIsAllowed() {
        let sut = makeSUT(smsState: .optInAndUnblock)
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        let expectedResult = ProfileViewModel.SectionCellDataSource(
            sectionOrder: sectionsOrder(),
            sectionRows: sectionRows(isSmsAllowed: true)
        )
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testSectionCells_whenAccountIsNotProFlexiBusinessNorMasterBusinessAccount_shouldNotIncludePlanSection() {
        let testAccountType = curriedTestSectionCellsForAccountType(
            expectedOrder: sectionsOrder(),
            expectedSectionRows: sectionRows()
        )
        
        testAccountType(.free)
        testAccountType(.proI)
        testAccountType(.proII)
        testAccountType(.proIII)
        testAccountType(.lite)
    }
    
    func testSectionCells_whenAccountIsProFlexiAccount_shouldIncludePlanSection() {
        let testAccountType = curriedTestSectionCellsForAccountType(
            expectedOrder: sectionsOrder(isPlanHidden: false),
            expectedSectionRows: sectionRows(isPlanHidden: false)
        )
        
        testAccountType(.proFlexi)
    }
    
    func testSectionCells_whenAccountIsBusinessAccount_shouldIncludePlanSection() {
        let testAccountType = curriedTestSectionCellsForAccountType(
            expectedOrder: sectionsOrder(isPlanHidden: false),
            expectedSectionRows: sectionRows(
                isPlanHidden: false,
                isBusiness: true
            )
        )
        
        testAccountType(.business)
    }
    
    func testSectionCells_whenAccountIsMasterBusinessAccount_shouldIncludePlanSection() {
        let testMasterBusinessAccountType = curriedTestSectionCellsForAccountType(
            expectedOrder: sectionsOrder(isPlanHidden: false),
            expectedSectionRows: sectionRows(
                isPlanHidden: false,
                isBusiness: true,
                isMasterBusinessAccount: true
            ),
            isMasterBusinessAccount: true
        )
        
        testMasterBusinessAccountType(.business)
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
    
    func testAction_changePassword_passwordCellShouldBeLoading() {
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
    
    func testAction_changeEmail_shouldPresentChangeController() {
        let sut = makeSUT(
            multiFactorAuthCheckResult: true,
            multiFactorAuthCheckDelay: 0.5
        )
        sut.dispatch(.onViewDidLoad)
        
        test(
            viewModel: sut,
            actions: [ProfileAction.changeEmail],
            expectedCommands: [.changeProfile(requestedChangeType: .email, isTwoFactorAuthenticationEnabled: true)]
        )
    }
    
    func testAction_changePassword_shouldPresentChangeController() {
        let sut = makeSUT(
            multiFactorAuthCheckResult: true,
            multiFactorAuthCheckDelay: 0.5
        )
        sut.dispatch(.onViewDidLoad)
        
        test(
            viewModel: sut,
            actions: [ProfileAction.changePassword],
            expectedCommands: [.changeProfile(requestedChangeType: .password, isTwoFactorAuthenticationEnabled: true)]
        )
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        currentAccountDetails: AccountDetailsEntity? = nil,
        email: String = "test@email.com",
        smsState: SMSStateEntity = .notAllowed,
        isMasterBusinessAccount: Bool = false,
        multiFactorAuthCheckResult: Bool = false,
        multiFactorAuthCheckDelay: TimeInterval = 0
    ) -> ProfileViewModel {
        
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: currentAccountDetails,
            email: email,
            isMasterBusinessAccount: isMasterBusinessAccount,
            smsState: smsState,
            multiFactorAuthCheckResult: multiFactorAuthCheckResult,
            multiFactorAuthCheckDelay: 1.0
        )
        
        return ProfileViewModel(accountUseCase: accountUseCase)
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
    
    private func curriedTestSectionCellsForAccountType(
        expectedOrder: [ProfileSection],
        expectedSectionRows: [ProfileSection: [ProfileSectionRow]],
        isMasterBusinessAccount: Bool = false
    ) -> (AccountTypeEntity) -> Void {
        { accountType in
            let expectedSections = ProfileViewModel.SectionCellDataSource(
                sectionOrder: expectedOrder,
                sectionRows: expectedSectionRows
            )
            let sut = self.makeSUT(
                currentAccountDetails: .init(proLevel: accountType),
                isMasterBusinessAccount: isMasterBusinessAccount
            )
            let result = self.receivedSectionDataSource(from: sut, after: .onViewDidLoad)
            XCTAssertEqual(result, expectedSections)
        }
    }
    
    private func sectionsOrder(isPlanHidden: Bool = true) -> [ProfileSection] {
        isPlanHidden ? [.profile, .security, .session] : [.profile, .security, .plan, .session]
    }
    
    private func sectionRows(
        isPlanHidden: Bool = true,
        isSmsAllowed: Bool = false,
        isBusiness: Bool = false,
        isMasterBusinessAccount: Bool = false
    ) -> [ProfileSection: [ProfileSectionRow]] {
        let profileRows: [ProfileSectionRow] = isBusiness && !isMasterBusinessAccount ?
            [.changePhoto, .changePassword(isLoading: false)] :
            [.changeName, .changePhoto, .changeEmail(isLoading: false), .changePassword(isLoading: false)]
        
        if isPlanHidden {
            return [
                .profile: isSmsAllowed ? profileRows + [.phoneNumber] : profileRows,
                .security: [.recoveryKey],
                .session: [.logout]
            ]
        } else {
            return [
                .profile: isSmsAllowed ? profileRows + [.phoneNumber] : profileRows,
                .security: [.recoveryKey],
                .plan: isBusiness ? [.upgrade, .role] : [.upgrade],
                .session: [.logout]
            ]
        }
    }
}
