import XCTest
import SwiftUI
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwiftUI
import MEGAFoundation
import Combine

final class PhotoCardViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testInit_defaultVaue() throws {
        let sut = PhotoCardViewModel(coverPhoto: nil, thumbnailUseCase: MockThumbnailUseCase())
        XCTAssertEqual(sut.thumbnailContainer, ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true))
    }
    
    func testLoadThumbnail_nonPlaceholder_doNotLoadLocalCacheAndDoNotLoadRemoteThumbnail() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("testLoadThumbnail_hasLocalCache_useLocalCache_local", isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)

        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent("testLoadThumbnail_hasLocalCache_useLocalCache_remote", isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedPreviewURL: localURL, loadPreviewResult: .success(remoteURL))
        )
        let loadedThumbnail = ImageContainer(image: Image(systemName: "heart"))
        sut.thumbnailContainer = loadedThumbnail
        sut.loadThumbnail()
        XCTAssertEqual(sut.thumbnailContainer, loadedThumbnail)
        XCTAssertNotEqual(sut.thumbnailContainer, URLImageContainer(imageURL: localURL))
        XCTAssertNotEqual(sut.thumbnailContainer, URLImageContainer(imageURL: remoteURL))
    }
    
    func testLoadThumbnail_placeholderAndHasLocalCache_useLocalCache() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("testLoadThumbnail_hasLocalCache_useLocalCache_local", isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)

        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent("testLoadThumbnail_hasLocalCache_useLocalCache_remote", isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(cachedPreviewURL: localURL, loadPreviewResult: .success(remoteURL))
        )
        XCTAssertEqual(sut.thumbnailContainer, ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true))
        sut.loadThumbnail()
        XCTAssertNotEqual(sut.thumbnailContainer, ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true))
        XCTAssertEqual(sut.thumbnailContainer, URLImageContainer(imageURL: localURL))
        XCTAssertNotEqual(sut.thumbnailContainer, URLImageContainer(imageURL: remoteURL))
    }

    func testLoadThumbnail_placeholderAndNoLocalCache_loadRemoteThumbnail() throws {
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent("testLoadThumbnail_hasLocalCache_useLocalCache_remote", isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCardViewModel(
            coverPhoto: NodeEntity(handle: 1),
            thumbnailUseCase: MockThumbnailUseCase(loadPreviewResult: .success(remoteURL))
        )
        XCTAssertEqual(sut.thumbnailContainer, ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true))
        
        let expectation = expectation(description: "thumbnailContainer is updated")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertEqual(container, URLImageContainer(imageURL: remoteURL))
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnail()
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotEqual(sut.thumbnailContainer, ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true))
        XCTAssertEqual(sut.thumbnailContainer, URLImageContainer(imageURL: remoteURL))
    }
}
