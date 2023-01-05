import XCTest
import Combine
import SwiftUI
import MEGADomainMock
import MEGADomain
import MEGASwiftUI
@testable import MEGA

final class AlbumCellViewModelTests: XCTestCase {
    private let album = AlbumEntity(id: 1, name: "Test", coverNode: NodeEntity(handle: 1), count: 15, type: .favourite)
    private var subscriptions = Set<AnyCancellable>()
    
    private var imageURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        imageURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isFileCreated = FileManager.default.createFile(atPath: imageURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isFileCreated)
    }
    
    func testInit_setTitleNodesAndTitlePublishers() throws {
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(), album: album)
        
        XCTAssertEqual(sut.title, album.name)
        XCTAssertEqual(sut.numberOfNodes, album.count)
        XCTAssertTrue(sut.thumbnailContainer.type == .placeholder)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLoadAlbumInfo_onThumbnailLoaded_loadingStateIsCorrect() throws {
        let thumbnail = ThumbnailEntity(url: imageURL, type: .thumbnail)
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(thumbnail)),
                                     album: album)
        
        let exp = expectation(description: "loading should change during loading of albums")
        exp.expectedFulfillmentCount = 2
        
        var results = [Bool]()
        sut.$isLoading
            .dropFirst()
            .sink {
                results.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.loadAlbumInfo()
        
        wait(for: [exp], timeout: 3.0)
        XCTAssertEqual(results, [true, false])
    }
    
    func testLoadAlbumInfo_onLoadThumbnail_thumbnailContainerIsUpdatedWithLoadedImage() throws {
        let thumbnail = ThumbnailEntity(url: imageURL, type: .thumbnail)
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(thumbnail)),
                                     album: album)
        
        let exp = expectation(description: "thumbnail image changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink {
                XCTAssertTrue($0.isEqual(URLImageContainer(imageURL: self.imageURL, type: .thumbnail)))
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadAlbumInfo()
        wait(for: [exp], timeout: 3.0)
    }
    
    func testLoadAlbumInfo_onLoadThumbnailFailed_thumbnailIsNotUpdatedAndLoadedIsFalse() throws {
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(),
                                     album: album)
        let exp = expectation(description: "thumbnail should not change")
        exp.isInverted = true
        
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadAlbumInfo()
        wait(for: [exp], timeout: 3.0)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testCancelLoading_verifyIsLoadingIsFalse() {
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(), album: album)
        sut.loadAlbumInfo()
        sut.cancelLoading()
        XCTAssertFalse(sut.isLoading)
    }
}
