@preconcurrency import Combine
@testable import ContentLibraries
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPreference
import MEGAPreferenceMocks
import MEGASwift
import Photos
import SwiftUI
import Testing
import XCTest

final class PhotoLibraryModeAllViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        ContentLibraries.configuration = .mockConfiguration()
        try super.setUpWithError()
    }

    @MainActor
    private func makeSUT(
        configuration: ContentLibraries.Configuration = .mockConfiguration()
    ) throws -> PhotoLibraryModeAllViewModel {
        let nodes =  [
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)
        ]
        let library = nodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .all
        return makeSUT(
            libraryViewModel: libraryViewModel,
            configuration: configuration)
    }
    
    @MainActor
    private func makeSUT(
        libraryViewModel: PhotoLibraryContentViewModel = .init(library: PhotoLibrary()),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        configuration: ContentLibraries.Configuration = .mockConfiguration()
    ) -> PhotoLibraryModeAllViewModel {
        .init(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: preferenceUseCase,
            devicePermissionHandler: devicePermissionHandler,
            configuration: configuration)
    }
    
    @MainActor
    func testInit_defaultValue() throws {
        let sut = try makeSUT(configuration: .mockConfiguration(featureFlags: [.mediaRevamp: true]))
        XCTAssertEqual(sut.photoCategoryList.count, 3)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-09-01T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[0].contentList,
                       [NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date)])
        
        XCTAssertEqual(sut.photoCategoryList[1].categoryDate, try "2022-08-18T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[1].contentList,
                       [NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                        NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date)])
        
        XCTAssertEqual(sut.photoCategoryList[2].categoryDate, try "2020-04-18T20:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[2].contentList,
                       [NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
                        NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
                        NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)])
        
        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .three, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
    }

    @MainActor
    func testZoomState_zoomInOneTime_daySection() throws {
        let sut = try makeSUT(configuration: .mockConfiguration(featureFlags: [.mediaRevamp: true]))
        sut.zoomState.zoom(.in)

        XCTAssertEqual(sut.photoCategoryList.count, 3)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-09-01T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[0].contentList,
                       [NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date)])

        XCTAssertEqual(sut.photoCategoryList[1].categoryDate, try "2022-08-18T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[1].contentList,
                       [NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                        NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date)])

        XCTAssertEqual(sut.photoCategoryList[2].categoryDate, try "2020-04-18T20:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[2].contentList,
                       [NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
                        NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
                        NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)])

        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .one, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
    }

    @MainActor
    func testZoomState_zoomInTwoTimes_daySection() throws {
        let sut = try makeSUT(configuration: .mockConfiguration(featureFlags: [.mediaRevamp: true]))
        sut.zoomState.zoom(.in)
        sut.zoomState.zoom(.in)

        XCTAssertEqual(sut.photoCategoryList.count, 3)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-09-01T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[0].contentList,
                       [NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date)])

        XCTAssertEqual(sut.photoCategoryList[1].categoryDate, try "2022-08-18T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[1].contentList,
                       [NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                        NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date)])

        XCTAssertEqual(sut.photoCategoryList[2].categoryDate, try "2020-04-18T20:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[2].contentList,
                       [NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
                        NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
                        NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)])

        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .one, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
    }

    @MainActor
    func testZoomState_zoomOutOneTime_monthSection() throws {
        let sut = try makeSUT(configuration: .mockConfiguration(featureFlags: [.mediaRevamp: true]))
        sut.zoomState.zoom(.out)

        XCTAssertEqual(sut.photoCategoryList.count, 3)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-09-01T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[0].contentList,
                       [NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date)])

        XCTAssertEqual(sut.photoCategoryList[1].categoryDate, try "2022-08-18T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[1].contentList,
                       [NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                        NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date)])

        XCTAssertEqual(sut.photoCategoryList[2].categoryDate, try "2020-04-18T20:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[2].contentList,
                       [NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
                        NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
                        NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)])

        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .five, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
    }

    @MainActor
    func testZoomState_zoomOutTwoTimes_monthSection() throws {
        let sut = try makeSUT(configuration: .mockConfiguration(featureFlags: [.mediaRevamp: true]))
        sut.zoomState.zoom(.out)
        sut.zoomState.zoom(.out)

        XCTAssertEqual(sut.photoCategoryList.count, 3)
        XCTAssertEqual(sut.photoCategoryList[0].categoryDate, try "2022-09-01T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[0].contentList,
                       [NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date)])

        XCTAssertEqual(sut.photoCategoryList[1].categoryDate, try "2022-08-18T22:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[1].contentList,
                       [NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
                        NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date)])

        XCTAssertEqual(sut.photoCategoryList[2].categoryDate, try "2020-04-18T20:01:04Z".date.removeDay(timeZone: .GMT))
        XCTAssertEqual(sut.photoCategoryList[2].contentList,
                       [NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
                        NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
                        NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date)])

        XCTAssertEqual(sut.zoomState, PhotoLibraryZoomState(scaleFactor: .five, maximumScaleFactor: .five, supportedScaleFactors: [.one, .three, .five]))
        XCTAssertNil(sut.position)
    }
    
    @MainActor
    func testZoomState_onChangeToThirteenScaleFactor_shouldChangeSelectionIsHidden() {
        let libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
        let viewModel = makeSUT(libraryViewModel: libraryViewModel)
        XCTAssertFalse(libraryViewModel.selection.isHidden)
        viewModel.zoomState.scaleFactor = .thirteen
        XCTAssertTrue(libraryViewModel.selection.isHidden)
    }
    
    @MainActor
    func testInvalidateCameraUploadEnabledSetting_whenIsCameraUploadsEnabledHasChanged_shouldTriggerShowEnableCameraUploadToEqualFalse() async {
        
        // Arrange
        let mockPreferences = MockPreferenceUseCase(dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false])
        let libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
        let sut = makeSUT(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: mockPreferences)
        
        let resultExpectation = expectation(description: "Expect showEnableCameraUpload to emit correct value")
        let subscription = sut.$bannerType
            .dropFirst(2)
            .sink { result in
                XCTAssertNil(result)
                resultExpectation.fulfill()
            }
        mockPreferences.dict[PreferenceKeyEntity.isCameraUploadsEnabled.rawValue] = true
        
        sut.invalidateCameraUploadEnabledSetting()
        
        // Assert
        await fulfillment(of: [resultExpectation], timeout: 1)
        subscription.cancel()
    }
    
    @MainActor
    func testInvalidateCameraUploadEnabledSetting_whenIsCameraUploadsEnabledHasNotChanged_shouldTriggerShowEnableCameraUploadToEqualTrue() async throws {
        
        // Arrange
        let mockPreferences = MockPreferenceUseCase(dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false])
        let libraryViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary())
        let sut = makeSUT(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: mockPreferences)
        
        let resultExpectation = expectation(description: "Expect banner type")
        resultExpectation.isInverted = true
        let subscription = sut.$bannerType
            .dropFirst(2)
            .sink { _ in
                resultExpectation.fulfill()
            }
        
        // Act
        sut.invalidateCameraUploadEnabledSetting()
        
        await fulfillment(of: [resultExpectation], timeout: 1)
        subscription.cancel()
        XCTAssertEqual(sut.bannerType, .enableCameraUploads)
    }
}

struct PhotoLibraryModeAllViewModelTestsSuite {
    @MainActor
    @Suite("Banners")
    struct Banners {
        @Test(arguments: [
            (true, Optional<PhotoLibraryBannerType>.none),
            (false, .enableCameraUploads)
        ])
        func mediaRevampDisabled(
            isCameraUploadsEnabled: Bool,
            expectedBanner: PhotoLibraryBannerType?
        ) async throws {
            let mockPreferences = MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: isCameraUploadsEnabled])
            let sut = makeSUT(
                preferenceUseCase: mockPreferences,
                configuration: .mockConfiguration(featureFlags: [.mediaRevamp: false]))
            
            try await confirmation { confirmation in
                let subscription = sut.$bannerType
                    .dropFirst()
                    .sink { result in
                        #expect(result == expectedBanner)
                        confirmation()
                    }
                
                try await Task.sleep(nanoseconds: 100_000_000)
                subscription.cancel()
            }
        }
        
        @Test
        func cameraUploadsDisabled() async throws {
            let mockPreferences = MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false])
            let sut = makeSUT(
                preferenceUseCase: mockPreferences,
                configuration: .mockConfiguration(featureFlags: [.mediaRevamp: true]))
            
            try await confirmation { confirmation in
                let subscription = sut.$bannerType
                    .dropFirst()
                    .sink { result in
                        #expect(result == .enableCameraUploads)
                        confirmation()
                    }
                
                try await Task.sleep(nanoseconds: 100_000_000)
                subscription.cancel()
            }
        }
        
        @Test(arguments: [
            (Date.now, Optional<PhotoLibraryBannerType>.none),
            (Date.now.addingTimeInterval(-(16 * 24 * 60 * 60)), .enableCameraUploads)
        ])
        func storedDate(
            storedDate: Date,
            expectedBanner: PhotoLibraryBannerType?
        ) async throws {
            let mockPreferences = MockPreferenceUseCase(dict: [
                PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false,
                PreferenceKeyEntity.lastEnableCameraUploadBannerDismissedDate.rawValue: storedDate])
            let sut = makeSUT(
                preferenceUseCase: mockPreferences,
                configuration: .mockConfiguration(
                    featureFlags: [.mediaRevamp: true]))
            
            try await confirmation { confirmation in
                let subscription = sut.$bannerType
                    .dropFirst()
                    .sink { result in
                        #expect(result == expectedBanner)
                        confirmation()
                    }
                
                try await Task.sleep(nanoseconds: 100_000_000)
                subscription.cancel()
            }
        }
        
        @Test(arguments: [
            (PHAuthorizationStatus.authorized, Optional<PhotoLibraryBannerType>.none),
            (.limited, .limitedPermissions)
        ])
        func limitedPermission(
            photoAuthorization: PHAuthorizationStatus,
            expectedBanner: PhotoLibraryBannerType?
        ) async throws {
            let mockPreferences = MockPreferenceUseCase(dict: [
                PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: true])
            let sut = makeSUT(
                preferenceUseCase: mockPreferences,
                devicePermissionHandler: MockDevicePermissionHandler(
                    photoAuthorization: photoAuthorization),
                configuration: .mockConfiguration(
                    featureFlags: [.mediaRevamp: true]))
            
            try await confirmation { confirmation in
                let subscription = sut.$bannerType
                    .dropFirst()
                    .sink { result in
                        #expect(result == expectedBanner)
                        confirmation()
                    }
                
                try await Task.sleep(nanoseconds: 100_000_000)
                subscription.cancel()
            }
        }
        
        @Test(arguments: [
            (Date.now, Optional<PhotoLibraryBannerType>.none),
            (Date.now.addingTimeInterval(-(16 * 24 * 60 * 60)), .limitedPermissions)
        ])
        func limitedAccessBannerContainsDismissedDate(
            storedDate: Date,
            expectedBanner: PhotoLibraryBannerType?
        ) async throws {
            let mockPreferences = MockPreferenceUseCase(dict: [
                PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: true,
                PreferenceKeyEntity.limitedPhotoAccessBannerDismissedDate.rawValue: storedDate
            ])
            let sut = makeSUT(
                preferenceUseCase: mockPreferences,
                devicePermissionHandler: MockDevicePermissionHandler(
                    photoAuthorization: .limited),
                configuration: .mockConfiguration(
                    featureFlags: [.mediaRevamp: true]))
            
            try await confirmation { confirmation in
                let subscription = sut.$bannerType
                    .dropFirst()
                    .sink { result in
                        #expect(result == expectedBanner)
                        confirmation()
                    }
                
                try await Task.sleep(nanoseconds: 100_000_000)
                subscription.cancel()
            }
        }
        
        @Test
        func dismissEnableCameraUploadBanner() async throws {
            let sut = makeSUT()
            
            sut.dismissEnableCameraUploadBanner()
            
            #expect(sut.lastEnableCameraUploadBannerDismissedDate != nil)
        }
        
        @Test
        func dismissLimitedAccessBanner() async throws {
            let sut = makeSUT()
            
            sut.dismissLimitedAccessBanner()
            
            #expect(sut.limitedPhotoAccessBannerDismissedDate != nil)
        }
    }
    
    @MainActor
    private static func makeSUT(
        libraryViewModel: PhotoLibraryContentViewModel = .init(library: PhotoLibrary()),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        configuration: ContentLibraries.Configuration = .mockConfiguration()
    ) -> PhotoLibraryModeAllViewModel {
        .init(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: preferenceUseCase,
            devicePermissionHandler: devicePermissionHandler,
            configuration: configuration)
    }
}

// MARK: - PhotoLibraryModeAllCollectionViewModel Tests

final class PhotoLibraryModeAllCollectionViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        ContentLibraries.configuration = .mockConfiguration()
        try super.setUpWithError()
    }

    @MainActor
    private func makeSUT(
        libraryViewModel: PhotoLibraryContentViewModel,
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        configuration: ContentLibraries.Configuration = .mockConfiguration()
    ) -> PhotoLibraryModeAllCollectionViewModel {
        .init(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: preferenceUseCase,
            configuration: configuration
        )
    }

    // MARK: - Tests for masonry layout section selection

    @MainActor
    func testInit_whenMediaRevampEnabledAndAlbumMode_usesMasonrySection() throws {
        // Arrange
        let nodes = [
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2025-09-01T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2026-01-18T22:01:04Z".date)
        ]
        let library = nodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library, contentMode: .album)

        // Act
        let sut = makeSUT(
            libraryViewModel: libraryViewModel,
            configuration: .mockConfiguration(featureFlags: [.mediaRevamp: true])
        )

        // Assert
        XCTAssertEqual(sut.photoCategoryList.count, 1, "Should use single masonry section for album mode with media revamp")
    }

    @MainActor
    func testInit_whenMediaRevampDisabledAndAlbumMode_usesDateSections() throws {
        // Arrange
        let nodes = [
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2025-09-01T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2026-01-18T22:01:04Z".date)
        ]
        let library = nodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library, contentMode: .album)

        // Act
        let sut = makeSUT(
            libraryViewModel: libraryViewModel,
            configuration: .mockConfiguration(featureFlags: [.mediaRevamp: false])
        )

        // Assert
        XCTAssertGreaterThan(sut.photoCategoryList.count, 1, "Should use date sections when media revamp is disabled")
    }

    @MainActor
    func testInit_whenMediaRevampEnabledButLibraryMode_usesDateSections() throws {
        // Arrange
        let nodes = [
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2025-09-01T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2026-01-18T22:01:04Z".date)
        ]
        let library = nodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library, contentMode: .library)

        // Act
        let sut = makeSUT(
            libraryViewModel: libraryViewModel,
            configuration: .mockConfiguration(featureFlags: [.mediaRevamp: true])
        )

        // Assert
        XCTAssertGreaterThan(sut.photoCategoryList.count, 1, "Should use date sections for library mode even with media revamp enabled")
    }

    @MainActor
    func testSubscribeToLibraryChange_whenLibraryUpdates_usesMasonrySection() async throws {
        // Arrange
        let nodes = [
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2025-09-01T22:01:04Z".date)
        ]
        let library = nodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library, contentMode: .album)

        let sut = makeSUT(
            libraryViewModel: libraryViewModel,
            configuration: .mockConfiguration(featureFlags: [.mediaRevamp: true])
        )

        // Act - update library to trigger subscription
        let newNodes = [
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2025-09-01T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 2, modificationTime: try "2026-01-02T22:01:04Z".date)
        ]
        let newLibrary = newNodes.toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)

        let expectation = expectation(description: "Wait for library change")
        let subscription = sut.$photoCategoryList
            .dropFirst()
            .sink { sections in
                XCTAssertEqual(sections.count, 1, "Should still use single masonry section after library update")
                expectation.fulfill()
            }

        libraryViewModel.library = newLibrary

        await fulfillment(of: [expectation], timeout: 1)
        subscription.cancel()
    }
}
