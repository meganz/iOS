import Combine
@testable import MEGA
import MEGADataMock
import XCTest

final class ProfileViewModelTests: XCTestCase {
    
    var subscriptions = Set<AnyCancellable>()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    func testAction_onViewDidLoad_deafultValue() {
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let sut = ProfileViewModel(sdk: mockSDK)
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
        sut.dispatch(.onViewDidLoad)
        
        // Assert
        wait(for: [expectation], timeout: 1)
        
        let expectedResult = ProfileViewModel.SectionCellDataSource(
            sectionOrder: [.profile, .security, .plan, .session],
            sectionRows: [
                .profile: [.changeName, .changePhoto, .changeEmail(isLoading: false), .changePassword(isLoading: false)],
                .security: [.recoveryKey],
                .plan: [.upgrade],
                .session: [.logout]
            ])
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testAction_onViewDidLoad_whenSmsIsAllowed() {
        // Arrange
        let mockSDK = MockSdk(smsState: .optInAndUnblock, myEmail: "test@email.com")
        let sut = ProfileViewModel(sdk: mockSDK)
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
        sut.dispatch(.onViewDidLoad)
        
        // Assert
        wait(for: [expectation], timeout: 1)
        
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
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let sut = ProfileViewModel(sdk: mockSDK)
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
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let sut = ProfileViewModel(sdk: mockSDK)
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
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let sut = ProfileViewModel(sdk: mockSDK)
        sut.dispatch(.onViewDidLoad)
        
        // Act & Assert
        test(viewModel: sut, actions: [ProfileAction.changeEmail], expectedCommands: [.changeProfile(requestedChangeType: .email, isTwoFactorAuthenticationEnabled: true)])
    }
    
    func testAction_changePasword_shouldPresentChangeControler() {
        
        // Arrange
        let mockSDK = MockSdk(myEmail: "test@email.com")
        let sut = ProfileViewModel(sdk: mockSDK)
        sut.dispatch(.onViewDidLoad)
        
        // Act & Assert
        test(viewModel: sut, actions: [ProfileAction.changePassword], expectedCommands: [.changeProfile(requestedChangeType: .password, isTwoFactorAuthenticationEnabled: true)])
    }
}
