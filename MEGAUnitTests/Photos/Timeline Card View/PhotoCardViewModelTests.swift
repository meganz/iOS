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
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
    }
    
    func testLoadThumbnail_nonPlaceholder_doNotLoadLocalCacheAndDoNotLoadRemoteThumbnail() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnailURLs: [(.preview, localURL)], loadPreviewResult: .success(remoteURL))
        )
        let loadedThumbnail = ImageContainer(image: Image(systemName: "heart"))
        sut.thumbnailContainer = loadedThumbnail
        sut.loadThumbnail()
        XCTAssertTrue(sut.thumbnailContainer.isEqual(loadedThumbnail))
        XCTAssertFalse(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL)))
        XCTAssertFalse(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remoteURL)))
    }
    
    func testLoadThumbnail_placeholderAndHasLocalCache_useLocalCache() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnailURLs: [(.preview, localURL)], loadPreviewResult: .success(remoteURL))
        )
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        sut.loadThumbnail()
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL)))
        XCTAssertFalse(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remoteURL)))
    }
    
    func testLoadThumbnail_placeholderAndNoLocalCache_loadRemoteThumbnail() throws {
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(loadPreviewResult: .success(remoteURL))
        )
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        
        let exp = expectation(description: "thumbnailContainer is updated")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(URLImageContainer(imageURL: remoteURL)))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnail()
        wait(for: [exp], timeout: 2.0)
        
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remoteURL)))
    }
    
    func testLoadThumbnail_noLocalCacheAndHasRemoteThumbnailAndPreview_loadBothThumbnailAndPreview() throws {
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath:remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remotePreviewImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemotePreviewFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remotePreviewImage.pngData())
        XCTAssertTrue(isRemotePreviewFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(remoteThumbnailURL),
                                                   loadPreviewResult: .success(remotePreviewURL))
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        
        let exp = expectation(description: "thumbnailContainer is updated")
        exp.expectedFulfillmentCount = 2
        var expectedContainers = [URLImageContainer(imageURL: remoteThumbnailURL), URLImageContainer(imageURL: remotePreviewURL)]
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(expectedContainers.removeFirst()))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnail()
        wait(for: [exp], timeout: 2.0)
        
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remotePreviewURL)))
        XCTAssertTrue(expectedContainers.isEmpty)
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndHasDifferentRemoteThumbnailAndPreview_loadBothThumbnailAndPreview() throws {
        let localThumbnailImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let localThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalThumbnailFileCreated = FileManager.default.createFile(atPath:localThumbnailURL.path, contents: localThumbnailImage.pngData())
        XCTAssertTrue(isLocalThumbnailFileCreated)
        
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath:remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remotePreviewImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemotePreviewFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remotePreviewImage.pngData())
        XCTAssertTrue(isRemotePreviewFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnailURLs: [(.thumbnail, localThumbnailURL)],
                                                   loadThumbnailResult: .success(remoteThumbnailURL),
                                                   loadPreviewResult: .success(remotePreviewURL))
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        
        let exp = expectation(description: "thumbnailContainer is updated")
        exp.expectedFulfillmentCount = 3
        var expectedContainers = [URLImageContainer(imageURL: localThumbnailURL),
                                  URLImageContainer(imageURL: remoteThumbnailURL),
                                  URLImageContainer(imageURL: remotePreviewURL)]
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(expectedContainers.removeFirst()))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnail()
        wait(for: [exp], timeout: 2.0)
        
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remotePreviewURL)))
        XCTAssertTrue(expectedContainers.isEmpty)
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndHasSameRemoteThumbnailAndPreview_onlyLoadPreview() throws {
        let localThumbnailImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let localThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalThumbnailFileCreated = FileManager.default.createFile(atPath:localThumbnailURL.path, contents: localThumbnailImage.pngData())
        XCTAssertTrue(isLocalThumbnailFileCreated)
        
        let remotePreviewImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemotePreviewFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remotePreviewImage.pngData())
        XCTAssertTrue(isRemotePreviewFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnailURLs: [(.thumbnail, localThumbnailURL)],
                                                   loadThumbnailResult: .success(localThumbnailURL),
                                                   loadPreviewResult: .success(remotePreviewURL))
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        
        let exp = expectation(description: "thumbnailContainer is updated")
        exp.expectedFulfillmentCount = 2
        var expectedContainers = [URLImageContainer(imageURL: localThumbnailURL),
                                  URLImageContainer(imageURL: remotePreviewURL)]
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(expectedContainers.removeFirst()))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnail()
        wait(for: [exp], timeout: 2.0)
        
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remotePreviewURL)))
        XCTAssertTrue(expectedContainers.isEmpty)
    }
}
