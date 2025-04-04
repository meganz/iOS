@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

final class APIEnvironmentRepositoryTests: XCTestCase {
    let sdk = MockSdk()
    let folderSdk = MockFolderSdk()
    var repo: APIEnvironmentRepository!
    
    private enum Constants {
        static let productionSDKUrl = "https://g.api.mega.co.nz/"
        static let stagingSDKUrl = "https://staging.api.mega.co.nz/"
        static let bt1444SDKUrl = "https://bt1.api.mega.co.nz:444/"
        static let sandbox3SDKUrl = "https://api-sandbox3.developers.mega.co.nz/"
    }
    
    override func setUpWithError() throws {
        repo = APIEnvironmentRepository(
            sdk: sdk,
            folderSdk: folderSdk,
            credentialRepository: MockCredentialRepository.newRepo,
            preferenceRepository: MockPreferenceRepository.newRepo
        )
    }
    
    func testChangeAPIURL_production() throws {
        repo.changeAPIURL(.production) {}
        XCTAssertEqual(sdk.apiURL, Constants.productionSDKUrl)
        XCTAssertFalse(try XCTUnwrap(sdk.disablepkp))
        XCTAssertEqual(folderSdk.apiURL, Constants.productionSDKUrl)
        XCTAssertFalse(try XCTUnwrap(folderSdk.disablepkp))
    }
    
    func testChangeAPIURL_staging() throws {
        repo.changeAPIURL(.staging) {}
        XCTAssertEqual(sdk.apiURL, Constants.stagingSDKUrl)
        XCTAssertFalse(try XCTUnwrap(sdk.disablepkp))
        XCTAssertEqual(folderSdk.apiURL, Constants.stagingSDKUrl)
        XCTAssertFalse(try XCTUnwrap(folderSdk.disablepkp))
    }
    
    func testChangeAPIURL_bt1444() throws {
        repo.changeAPIURL(.bt1444) {}
        XCTAssertEqual(sdk.apiURL, Constants.bt1444SDKUrl)
        XCTAssertTrue(try XCTUnwrap(sdk.disablepkp))
        XCTAssertEqual(folderSdk.apiURL, Constants.bt1444SDKUrl)
        XCTAssertTrue(try XCTUnwrap(folderSdk.disablepkp))
    }
     
    func testChangeAPIURL_sandbox() throws {
        repo.changeAPIURL(.sandbox3) {}
        XCTAssertEqual(sdk.apiURL, Constants.sandbox3SDKUrl)
        XCTAssertTrue(try XCTUnwrap(sdk.disablepkp))
        XCTAssertEqual(folderSdk.apiURL, Constants.sandbox3SDKUrl)
        XCTAssertTrue(try XCTUnwrap(folderSdk.disablepkp))
    }
}
