import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class AccountUseCaseTests: XCTestCase {

    func testUpgradeSecurity_shouldReturnSuccess() async throws {
        let sut = AccountUseCase(repository: MockAccountRepository(isUpgradeSecuritySuccess: true))
        let isSuccess = try await sut.upgradeSecurity()
        XCTAssertTrue(isSuccess)
    }
    
    func testIsNewAccount_accountIsNew_shouldReturnTrue() {
        let sut = AccountUseCase(repository: MockAccountRepository(isNewAccount: true))
        XCTAssertTrue(sut.isNewAccount)
    }
    
    func testIsNewAccount_accountIsAnExistingAccount_shouldReturnFalse() {
        let sut = AccountUseCase(repository: MockAccountRepository(isNewAccount: false))
        XCTAssertFalse(sut.isNewAccount)
    }
    
    func testCurrentAccountDetails_shouldReturnCurrentAccountDetails() {
        let accountDetails = AccountDetailsEntity.random
        let sut = AccountUseCase(repository: MockAccountRepository(currentAccountDetails: accountDetails))
        
        XCTAssertEqual(sut.currentAccountDetails, accountDetails)
    }
    
    func testBandwidthOverquotaDelay_returnBandwidth() {
        let expectedBandwidth: Int64 = 100
        let sut = AccountUseCase(repository: MockAccountRepository(bandwidthOverquotaDelay: expectedBandwidth))
        XCTAssertEqual(sut.bandwidthOverquotaDelay, expectedBandwidth)
    }
    
    func testRefreshCurrentAccountDetails_whenSuccess_shouldReturnAccountDetails() async throws {
        let accountDetails = AccountDetailsEntity.random
        let sut = AccountUseCase(repository: MockAccountRepository(accountDetailsResult: .success(accountDetails)))
        
        let currentAccountDetails = try await sut.refreshCurrentAccountDetails()
        XCTAssertEqual(currentAccountDetails, accountDetails)
    }
    
    func testRefreshCurrentAccountDetails_whenFails_shouldThrowGenericError() async {
        let sut = AccountUseCase(repository: MockAccountRepository(accountDetailsResult: .failure(.generic)))
        
        await XCTAsyncAssertThrowsError(try await sut.refreshCurrentAccountDetails()) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountDetailsErrorEntity, .generic)
        }
    }
    
    func testGetMiscFlag_whenSuccess_shouldNotThrow() async {
        let sut = AccountUseCase(repository: MockAccountRepository(miscFlagsResult: .success))
        
        await XCTAsyncAssertNoThrow(try await sut.getMiscFlags())
    }
    
    func testGetMiscFlag_whenFail_shouldThrowGenericError() async throws {
        let sut = AccountUseCase(repository: MockAccountRepository(miscFlagsResult: .failure(.generic)))
        
        await XCTAsyncAssertThrowsError(try await sut.getMiscFlags()) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, .generic)
        }
    }
    
    func testSessionTransferURL_whenSuccess_shouldReturnURL() async throws {
        let urlPath = "https://mega.nz"
        let expectedURL = try XCTUnwrap(URL(string: urlPath))
        let sut = AccountUseCase(repository: MockAccountRepository(sessionTransferURLResult: .success(expectedURL)))
                                 
        let urlResult = try await sut.sessionTransferURL(path: urlPath)
        
        XCTAssertEqual(urlResult, expectedURL)
    }
    
    func testSessionTransferURL_whenFail_shouldThrowGenericError() async throws {
        let urlPath = "https://mega.nz"
        let sut = AccountUseCase(repository: MockAccountRepository(sessionTransferURLResult: .failure(.generic)))
                                 
        await XCTAsyncAssertThrowsError(try await sut.sessionTransferURL(path: urlPath)) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, .generic)
        }
    }
}
