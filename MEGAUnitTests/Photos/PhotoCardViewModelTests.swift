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
            thumbnailUseCase: MockThumbnailUseCase(cachedPreviewURL: localURL, loadPreviewResult: .success(remoteURL))
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
            thumbnailUseCase: MockThumbnailUseCase(cachedPreviewURL: localURL, loadPreviewResult: .success(remoteURL))
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
        wait(for: [exp], timeout: 3.0)
        
        XCTAssertFalse(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)))
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remoteURL)))
    }
}
