import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class UserAttributeRepositoryTests: XCTestCase {
    
    func testMergeUserAttribute_forContentConsumptionPreferences_withNoOrigianlStoredValue_shouldSaveCorrectly() async throws {
        let json = ""
        let targetJson = """
        {"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive","usePreference":true}}}
        """.trim

        let key = ContentConsumptionKeysEntity.key
        let (sut, sdk) = sut(
            contentConsumptionPreferences: [key: try XCTUnwrap(json)])
        let objectToSave = ContentConsumptionEntity(
            ios: .init(
                timeline: .init(mediaType: .videos, location: .cloudDrive, usePreference: true))
        )
        
        try await sut.mergeUserAttribute(
            .contentConsumptionPreferences,
            key: ContentConsumptionKeysEntity.key,
            object: objectToSave)
        
        XCTAssertEqual(sdk.contentConsumptionPreferences[key]?.sorted(), try XCTUnwrap(targetJson).sorted())
    }

    func testMergeUserAttribute_forContentConsumptionPreferences_withIosChangesOnly_shouldSaveCorrectly() async throws {
        let json = """
                {"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive","usePreference":true}}}
            """
        let targetJson = """
            {"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive","usePreference":false}}}
            """.trim
        let key = ContentConsumptionKeysEntity.key
        let (sut, sdk) = sut(
            contentConsumptionPreferences: [key: try XCTUnwrap(json)])
        let objectToSave = ContentConsumptionEntity(
            ios: .init(
                timeline: .init(mediaType: .videos, location: .cloudDrive, usePreference: false))
        )
        
        try await sut.mergeUserAttribute(
            .contentConsumptionPreferences,
            key: ContentConsumptionKeysEntity.key,
            object: objectToSave)
        
        XCTAssertEqual(sdk.contentConsumptionPreferences[key]?.sorted(), try XCTUnwrap(targetJson).sorted())
    }
    
    func testMergeUserAttribute_forContentConsumptionPreferences_withCrossPlatformData_shouldChangeOnlyiOSBlock() async throws {
        let json = """
                {"ios":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
            """.trim
        let targetJson = """
                {"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive","usePreference":false}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
            """.trim
        let key = ContentConsumptionKeysEntity.key
        let (sut, sdk) = sut(
            contentConsumptionPreferences: [key: try XCTUnwrap(json)])
        let objectToSave = ContentConsumptionEntity(
            ios: .init(
                timeline: .init(mediaType: .videos, location: .cloudDrive, usePreference: false))
            )
        
        try await sut.mergeUserAttribute(
            .contentConsumptionPreferences,
            key: ContentConsumptionKeysEntity.key,
            object: objectToSave)
        
        XCTAssertEqual(sdk.contentConsumptionPreferences[key]?.sorted(), try XCTUnwrap(targetJson).sorted())
    }
    
        func testMergeUserAttribute_forContentConsumptionPreferences_withOnlyHavingCrossPlatformData_shouldAddiOSBlockCorrectlyWithOtherPlatformData() async throws {
        let json = """
                {"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
            """.trim
        let targetJson = """
                {"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive","usePreference":false}}}
            """.trim
            let key = ContentConsumptionKeysEntity.key
            let (sut, sdk) = sut(
                contentConsumptionPreferences: [key: try XCTUnwrap(json)])
            let objectToSave = ContentConsumptionEntity(
                ios: .init(
                    timeline: .init(mediaType: .videos, location: .cloudDrive, usePreference: false))
                )
            
            try await sut.mergeUserAttribute(
                .contentConsumptionPreferences,
                key: ContentConsumptionKeysEntity.key,
                object: objectToSave)
            
            XCTAssertEqual(sdk.contentConsumptionPreferences[key]?.sorted(), try XCTUnwrap(targetJson).sorted())
    }
    
    private func sut(contentConsumptionPreferences: [String: String] = [:]) -> (UserAttributeRepository, MockSdk) {
        let sdk = MockSdk(contentConsumptionPreferences: contentConsumptionPreferences)
        return (UserAttributeRepository(sdk: sdk), sdk)
    }
}
