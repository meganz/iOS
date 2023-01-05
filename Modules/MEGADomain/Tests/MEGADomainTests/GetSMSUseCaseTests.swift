import XCTest
import MEGADomain
import MEGADomainMock

final class GetSMSUseCaseTests: XCTestCase {
    func testVerifiedPhoneNumber_nil() {
        let repo = MockSMSRepository(verifiedNumber: nil)
        let sut = GetSMSUseCase(repo: repo, l10n: MockL10nRepository())
        XCTAssertNil(sut.verifiedPhoneNumber())
    }
    
    func testVerifiedPhoneNumber_notNil() {
        let number = "0101010101"
        let repo = MockSMSRepository(verifiedNumber: number)
        let sut = GetSMSUseCase(repo: repo, l10n: MockL10nRepository())
        XCTAssertEqual(sut.verifiedPhoneNumber(), number)
    }
    
    func testGetRegionCallingCodes_success_matchCurrentRegion() {
        let mockRegions = [RegionEntity(regionCode: "NZ", regionName: nil, callingCodes: ["+64"])]
        let sut = GetSMSUseCase(repo: MockSMSRepository(regionCodesResult: .success(mockRegions)),
                                l10n: MockL10nRepository())
        
        sut.getRegionCallingCodes { result in
            switch result {
            case .failure:
                XCTFail("errors are not expected!")
            case .success(let list):
                XCTAssertEqual(list.currentRegion, RegionEntity(regionCode: "NZ", regionName: "New Zealand", callingCodes: ["+64"]))
                XCTAssertEqual(list.allRegions, [RegionEntity(regionCode: "NZ", regionName: "New Zealand", callingCodes: ["+64"])])
            }
        }
    }
    
    func testGetRegionCallingCodes_success_doesNotmatchCurrentRegion() {
        let mockRegions = [RegionEntity(regionCode: "NZ", regionName: nil, callingCodes: ["+64"])]
        let sut = GetSMSUseCase(repo: MockSMSRepository(regionCodesResult: .success(mockRegions)),
                                l10n: MockL10nRepository(appLanguage: "en", deviceRegion: "AU"))
        
        sut.getRegionCallingCodes { result in
            switch result {
            case .failure:
                XCTFail("errors are not expected!")
            case .success(let list):
                XCTAssertNil(list.currentRegion)
                XCTAssertEqual(list.allRegions, [RegionEntity(regionCode: "NZ", regionName: "New Zealand", callingCodes: ["+64"])])
            }
        }
    }
    
    func testGetRegionCallingCodes_error() {
        let errors: [GetSMSErrorEntity] = [.failedToGetCallingCodes, .generic]
        
        for mockError in errors {
            let sut = GetSMSUseCase(repo: MockSMSRepository(regionCodesResult: .failure(mockError)),
                                    l10n: MockL10nRepository())
            
            sut.getRegionCallingCodes { result in
                switch result {
                case .failure(let error):
                    XCTAssertEqual(mockError, error)
                case .success:
                    XCTFail("error \(mockError) is expected!")
                }
            }
        }
    }
}
