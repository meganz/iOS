import MEGADomain
import MEGADomainMock
import Testing

@Suite("Get SMS Use Case Tests - Validates core functionalities of GetSMSUseCase.")
struct GetSMSUseCaseTests {
    private static let samplePhoneNumber = "0101010101"
    private static let mockRegionCodeNZ = "NZ"
    private static let mockCallingCodesNZ = ["+64"]
    private static let mockRegionEntityNZ = RegionEntity(
        regionCode: "NZ",
        regionName: "New Zealand",
        callingCodes: ["+64"]
    )
    
    private static func makeSUT(repo: MockSMSRepository, language: String = "en", deviceRegion: String = "NZ") -> GetSMSUseCaseProtocol {
        GetSMSUseCase(
            repo: repo,
            l10n: MockL10nRepository(
                appLanguage: language,
                deviceRegion: deviceRegion
            )
        )
    }
    
    private static func assertVerifiedPhoneNumber(sut: GetSMSUseCaseProtocol, expectedNumber: String?) {
        #expect(sut.verifiedPhoneNumber() == expectedNumber, "Expected verified phone number to be \(expectedNumber ?? "nil") but got \(sut.verifiedPhoneNumber() ?? "nil")")
    }
    
    private static func assertRegionCallingCodes(
        sut: GetSMSUseCaseProtocol,
        expectedCurrentRegion: RegionEntity?,
        expectedAllRegions: [RegionEntity]
    ) async {
        do {
            let list = try await sut.getRegionCallingCodes()
            #expect(list.currentRegion == expectedCurrentRegion, "Expected current region to match \(expectedCurrentRegion?.regionCode ?? "nil") but got \(list.currentRegion?.regionCode ?? "nil")")
            #expect(list.allRegions == expectedAllRegions, "Expected all regions to match \(expectedAllRegions) but got \(list.allRegions)")
        } catch {
            Issue.record("Unexpected error occurred!")
        }
    }
    
    private static func assertErrorHandling(
        mockError: GetSMSErrorEntity,
        sut: GetSMSUseCaseProtocol
    ) async {
        do {
            _ = try await sut.getRegionCallingCodes()
            Issue.record("Expected error \(mockError) but no error occurred.")
        } catch let error as GetSMSErrorEntity {
            #expect(error == mockError, "Expected error \(mockError) but got \(error)")
        } catch {
            Issue.record("Unexpected error occurred when expecting \(mockError)")
        }
    }
    
    // MARK: - Phone Number Verification Tests
    @Suite("Phone Number Verification - Checks if the verified phone number is correct.")
    struct PhoneNumberVerificationTests {
        
        @Test("Returns nil when phone number is not verified.")
        func returnsNilWhenPhoneNumberNotVerified() {
            let sut = makeSUT(repo: MockSMSRepository.newRepo)
            assertVerifiedPhoneNumber(sut: sut, expectedNumber: nil)
        }
        
        @Test("Returns verified phone number when set.")
        func returnsVerifiedPhoneNumberWhenSet() {
            let sut = makeSUT(repo: MockSMSRepository(verifiedNumber: samplePhoneNumber))
            assertVerifiedPhoneNumber(sut: sut, expectedNumber: samplePhoneNumber)
        }
    }

    // MARK: - Region Calling Codes Tests
    @Suite("Region Calling Codes - Validates fetching and matching region calling codes.")
    struct RegionCallingCodesTests {
        
        @Test("Returns current region when device region matches.")
        func returnsCurrentRegionForMatchingDeviceRegion() async {
            let mockRegions = [RegionEntity(regionCode: mockRegionCodeNZ, regionName: nil, callingCodes: mockCallingCodesNZ)]
            let sut = makeSUT(repo: MockSMSRepository(regionCodesResult: .success(mockRegions)))
            
            await assertRegionCallingCodes(
                sut: sut,
                expectedCurrentRegion: mockRegionEntityNZ,
                expectedAllRegions: [mockRegionEntityNZ]
            )
        }
        
        @Test("Returns nil for current region when device region does not match.")
        func returnsNilForNonMatchingDeviceRegion() async {
            let mockRegions = [RegionEntity(regionCode: mockRegionCodeNZ, regionName: nil, callingCodes: mockCallingCodesNZ)]
            let sut = makeSUT(repo: MockSMSRepository(regionCodesResult: .success(mockRegions)), deviceRegion: "AU")
            
            await assertRegionCallingCodes(
                sut: sut,
                expectedCurrentRegion: nil,
                expectedAllRegions: [mockRegionEntityNZ]
            )
        }
    }
    
    // MARK: - Error Handling Tests
    @Suite("Error Handling - Validates correct error handling for region calling codes fetch.")
    struct ErrorHandlingTests {
        
        @Test("Returns expected error when fetching region calling codes fails.", arguments: [
            GetSMSErrorEntity.failedToGetCallingCodes, GetSMSErrorEntity.generic
        ])
        func returnsExpectedErrorOnFailedRegionFetch(error: GetSMSErrorEntity) async {
            let sut = makeSUT(repo: MockSMSRepository(regionCodesResult: .failure(error)))
            await assertErrorHandling(
                mockError: error,
                sut: sut
            )
        }
    }
}
