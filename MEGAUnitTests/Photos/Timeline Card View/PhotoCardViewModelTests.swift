import XCTest
import SwiftUI
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwiftUI
import MEGAFoundation
import Combine
import MEGASwift

final class PhotoCardViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testInit_defaultVaue() throws {
        let sut = PhotoCardViewModel(coverPhoto: nil, thumbnailUseCase: MockThumbnailUseCase())
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
    }
    
    func testLoadThumbnail_nonPlaceholder_doNotLoadLocalCacheAndDoNotLoadRemoteThumbnail() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath: localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath: remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .preview)],
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remoteURL, type: .preview)))
        )
        let loadedThumbnail = ImageContainer(image: Image(systemName: "heart"), type: .thumbnail)
        sut.thumbnailContainer = loadedThumbnail
        sut.loadThumbnail()
        XCTAssertTrue(sut.thumbnailContainer.isEqual(loadedThumbnail))
        XCTAssertFalse(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .preview)))
        XCTAssertFalse(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remoteURL, type: .preview)))
    }
    
    func testLoadThumbnail_placeholderAndHasLocalCache_useLocalCache() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath: localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath: remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .preview)],
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remoteURL, type: .preview)))
        )
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        sut.loadThumbnail()
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .preview)))
        XCTAssertFalse(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remoteURL, type: .preview)))
    }
    
    func testLoadThumbnail_placeholderAndNoLocalCache_loadRemoteThumbnail() throws {
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath: remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(loadPreviewResult: .success(ThumbnailEntity(url: remoteURL, type: .preview)))
        )
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        
        let exp = expectation(description: "thumbnailContainer is updated")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(URLImageContainer(imageURL: remoteURL, type: .preview)))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnail()
        wait(for: [exp], timeout: 2.0)
        
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remoteURL, type: .preview)))
    }
    
    func testLoadThumbnail_noLocalCacheAndHasRemoteThumbnailAndPreview_loadBothThumbnailAndPreview() throws {
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath: remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remotePreviewImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemotePreviewFileCreated = FileManager.default.createFile(atPath: remotePreviewURL.path, contents: remotePreviewImage.pngData())
        XCTAssertTrue(isRemotePreviewFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: remoteThumbnailURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview)))
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        
        let exp = expectation(description: "thumbnailContainer is updated")
        exp.expectedFulfillmentCount = 2
        var expectedContainers = [URLImageContainer(imageURL: remoteThumbnailURL, type: .thumbnail),
                                  URLImageContainer(imageURL: remotePreviewURL, type: .preview)]
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(expectedContainers.removeFirst()))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnail()
        wait(for: [exp], timeout: 2.0)
        
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remotePreviewURL, type: .preview)))
        XCTAssertTrue(expectedContainers.isEmpty)
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndHasDifferentRemoteThumbnailAndPreview_loadBothThumbnailAndPreview() throws {
        let localThumbnailImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let localThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalThumbnailFileCreated = FileManager.default.createFile(atPath: localThumbnailURL.path, contents: localThumbnailImage.pngData())
        XCTAssertTrue(isLocalThumbnailFileCreated)
        
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath: remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remotePreviewImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemotePreviewFileCreated = FileManager.default.createFile(atPath: remotePreviewURL.path, contents: remotePreviewImage.pngData())
        XCTAssertTrue(isRemotePreviewFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localThumbnailURL, type: .thumbnail)],
                                                   loadThumbnailResult: .success(ThumbnailEntity(url: remoteThumbnailURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview)))
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        
        let exp = expectation(description: "thumbnailContainer is updated")
        exp.expectedFulfillmentCount = 3
        var expectedContainers = [URLImageContainer(imageURL: localThumbnailURL, type: .thumbnail),
                                  URLImageContainer(imageURL: remoteThumbnailURL, type: .thumbnail),
                                  URLImageContainer(imageURL: remotePreviewURL, type: .preview)]
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(expectedContainers.removeFirst()))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnail()
        wait(for: [exp], timeout: 2.0)
        
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remotePreviewURL, type: .preview)))
        XCTAssertTrue(expectedContainers.isEmpty)
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndHasSameRemoteThumbnailAndPreview_onlyLoadPreview() throws {
        let localThumbnailImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let localThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalThumbnailFileCreated = FileManager.default.createFile(atPath: localThumbnailURL.path, contents: localThumbnailImage.pngData())
        XCTAssertTrue(isLocalThumbnailFileCreated)
        
        let remotePreviewImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemotePreviewFileCreated = FileManager.default.createFile(atPath: remotePreviewURL.path, contents: remotePreviewImage.pngData())
        XCTAssertTrue(isRemotePreviewFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localThumbnailURL, type: .thumbnail)],
                                                   loadThumbnailResult: .success(ThumbnailEntity(url: localThumbnailURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview)))
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        
        let exp = expectation(description: "thumbnailContainer is updated")
        exp.expectedFulfillmentCount = 2
        var expectedContainers = [URLImageContainer(imageURL: localThumbnailURL, type: .thumbnail),
                                  URLImageContainer(imageURL: remotePreviewURL, type: .preview)]
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(expectedContainers.removeFirst()))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnail()
        wait(for: [exp], timeout: 2.0)
        
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), type: .placeholder)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remotePreviewURL, type: .preview)))
        XCTAssertTrue(expectedContainers.isEmpty)
    }
}
