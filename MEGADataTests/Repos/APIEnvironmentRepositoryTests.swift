import ChatRepoMock
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class APIEnvironmentRepositoryTests: XCTestCase {
    let sdk = MockSdk()
    let folderSdk = MockFolderSdk()
    let chatSdk = MockChatSDK()
    var repo: APIEnvironmentRepository!
    var disablepkp: Bool!
    
    private enum Constants {
        static let productionSDKUrl = "https://g.api.mega.co.nz/"
        static let stagingSDKUrl = "https://staging.api.mega.co.nz/"
        static let bt1444SDKUrl = "https://bt1.api.mega.co.nz:444/"
        static let sandbox3SDKUrl = "https://api-sandbox3.developers.mega.co.nz/"
    }
    
    override func setUpWithError() throws {
        disablepkp = false
        
        repo = APIEnvironmentRepository(sdk: sdk,
                                folderSdk: folderSdk,
                                credentialRepository: MockCredentialRepository.newRepo)
    }
    
    func testChangeAPIURL_production() throws {
        repo.changeAPIURL(.production) {}
        XCTAssertEqual(sdk.apiURL, Constants.productionSDKUrl)
        disablepkp = try XCTUnwrap(sdk.disablepkp)
        XCTAssertFalse(disablepkp)
        XCTAssertEqual(folderSdk.apiURL, Constants.productionSDKUrl)
        disablepkp = try XCTUnwrap(folderSdk.disablepkp)
        XCTAssertFalse(disablepkp)
    }
    
    func testChangeAPIURL_staging() throws {
        repo.changeAPIURL(.staging) {}
        XCTAssertEqual(sdk.apiURL, Constants.stagingSDKUrl)
        disablepkp = try XCTUnwrap(sdk.disablepkp)
        XCTAssertFalse(disablepkp)
        XCTAssertEqual(folderSdk.apiURL, Constants.stagingSDKUrl)
        disablepkp = try XCTUnwrap(folderSdk.disablepkp)
        XCTAssertFalse(disablepkp)
    }
    
    func testChangeAPIURL_bt1444() throws {
        repo.changeAPIURL(.bt1444) {}
        XCTAssertEqual(sdk.apiURL, Constants.bt1444SDKUrl)
        disablepkp = try XCTUnwrap(sdk.disablepkp)
        XCTAssertTrue(disablepkp)
        XCTAssertEqual(folderSdk.apiURL, Constants.bt1444SDKUrl)
        disablepkp = try XCTUnwrap(folderSdk.disablepkp)
        XCTAssertTrue(disablepkp)
    }
     
    func testChangeAPIURL_sandbox() throws {
        repo.changeAPIURL(.sandbox3) {}
        XCTAssertEqual(sdk.apiURL, Constants.sandbox3SDKUrl)
        disablepkp = try XCTUnwrap(sdk.disablepkp)
        XCTAssertTrue(disablepkp)
        XCTAssertEqual(folderSdk.apiURL, Constants.sandbox3SDKUrl)
        disablepkp = try XCTUnwrap(folderSdk.disablepkp)
        XCTAssertTrue(disablepkp)
    }
}
