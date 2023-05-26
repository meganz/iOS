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
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(), album: album, selection: AlbumSelection())
        
        XCTAssertEqual(sut.title, album.name)
        XCTAssertEqual(sut.numberOfNodes, album.count)
        XCTAssertTrue(sut.thumbnailContainer.type == .placeholder)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLoadAlbumThumbnail_onThumbnailLoaded_loadingStateIsCorrect() throws {
        let thumbnail = ThumbnailEntity(url: imageURL, type: .thumbnail)
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(thumbnail)), album: album, selection: AlbumSelection())
        
        let exp = expectation(description: "loading should change during loading of albums")
        exp.expectedFulfillmentCount = 2
        
        var results = [Bool]()
        sut.$isLoading
            .dropFirst()
            .sink {
                results.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.loadAlbumThumbnail()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(results, [true, false])
    }
    
    func testLoadAlbumThumbnail_onLoadThumbnail_thumbnailContainerIsUpdatedWithLoadedImageIfContainerIsCurrentlyPlaceholder() throws {
        let thumbnail = ThumbnailEntity(url: imageURL, type: .thumbnail)
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(thumbnail)), album: album, selection: AlbumSelection())
        
        let exp = expectation(description: "thumbnail image changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink {
                XCTAssertTrue($0.isEqual(URLImageContainer(imageURL: self.imageURL, type: .thumbnail)))
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadAlbumThumbnail()
        wait(for: [exp], timeout: 1.0)
    }
    
    func testLoadAlbumThumbnail_onLoadThumbnailFailed_thumbnailIsNotUpdatedAndLoadedIsFalse() throws {
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(),
                                     album: album, selection: AlbumSelection())
        let exp = expectation(description: "thumbnail should not change")
        exp.isInverted = true
        
        sut.$thumbnailContainer
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadAlbumThumbnail()
        wait(for: [exp], timeout: 1.0)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testThumbnailContainer_cachedThumbnail_setThumbnailContainerWithoutPlaceholder() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail)]),
                                     album: album, selection: AlbumSelection())
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        
        let exp = expectation(description: "thumbnail should not update again")
        exp.isInverted = true
        sut.$thumbnailContainer
            .dropFirst()
            .sink {_ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadAlbumThumbnail()
        wait(for: [exp], timeout: 1.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
    }
    
    func testLoadAlbumThumbnail_cachedThumbnail_shouldNotLoadThumbnailAgain() throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail)]),
                                     album: album, selection: AlbumSelection())
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        
        let exp = expectation(description: "loading flag should not change")
        exp.isInverted = true
        sut.$isLoading
            .dropFirst()
            .sink {_ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadAlbumThumbnail()
        wait(for: [exp], timeout: 1.0)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testCancelLoading_verifyIsLoadingIsFalse() {
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(), album: album, selection: AlbumSelection())
        sut.loadAlbumThumbnail()
        sut.cancelLoading()
        XCTAssertFalse(sut.isLoading)
    }
    
    func testIsSelected_whenUserTapOnAlbum_shouldBeSelected() {
        let selection = AlbumSelection()
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(), album: album, selection: selection)
        sut.isSelected = true
        
        XCTAssertTrue(selection.isAlbumSelected(album))
    }
    
    func testShouldShowEditStateOpacity_whenAlbumListEditingAndonUserAlbum_shouldReturnRightValue() {
        let selection = AlbumSelection()
        let userAlbum1 = AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                                       count: 1, type: .user, modificationTime: nil)
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(), album: userAlbum1, selection: selection )
        
        let exp = expectation(description: "Should set shouldShowEditStateOpacity to 1.0")
        exp.expectedFulfillmentCount = 2
        
        var result = [Double]()
        
        sut.$shouldShowEditStateOpacity
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        selection.editMode = .active
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [0.0, 1.0])
    }
    
    func testShouldShowEditStateOpacity_whenAlbumListEditingAndonSystemAlbum_shouldReturnRightValue() {
        let selection = AlbumSelection()
        let systemAlbum = AlbumEntity(id: 4, name: "Gif", coverNode: NodeEntity(handle: 3),
                                                       count: 1, type: .gif, modificationTime: nil)
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(), album: systemAlbum, selection: selection )
        
        let exp = expectation(description: "Should set shouldShowEditStateOpaicity to 0.0")
        exp.expectedFulfillmentCount = 2
        
        var result = [Double]()
        
        sut.$shouldShowEditStateOpacity
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        selection.editMode = .active
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [0.0, 0.0])
    }
    
    func testOpacity_whenAlbumListEditingAndUserAlbum_shouldReturnRightValue() {
        let selection = AlbumSelection()
        let userAlbum1 = AlbumEntity(id: 4, name: "Album 1", coverNode: NodeEntity(handle: 3),
                                                       count: 1, type: .user, modificationTime: nil)
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(), album: userAlbum1, selection: selection)
        
        let exp = expectation(description: "Should set shouldShowEditStateOpacity to 1.0")
        exp.expectedFulfillmentCount = 2
        
        var result = [Double]()
        
        sut.$opacity
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        selection.editMode = .active
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [1.0, 1.0])
    }
    
    func testOpacity_whenAlbumListEditingAndSystemAlbum_shouldReturnRightValue() {
        let selection = AlbumSelection()
        let systemAlbum = AlbumEntity(id: 4, name: "Gif", coverNode: NodeEntity(handle: 3),
                                                       count: 1, type: .gif, modificationTime: nil)
        let sut = AlbumCellViewModel(thumbnailUseCase: MockThumbnailUseCase(), album: systemAlbum, selection: selection)
        
        let exp = expectation(description: "Should set shouldShowEditStateOpacity to 0.5")
        exp.expectedFulfillmentCount = 2
        
        var result = [Double]()
        
        sut.$opacity
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        selection.editMode = .active
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [1.0, 0.5])
    }
    
    func testOnAlbumTap_whenUserTapOnAlbumCell_ShouldToggleForCustomAlbums() {
        let sut = AlbumCellViewModel(
            thumbnailUseCase: MockThumbnailUseCase(),
            album: AlbumEntity(id: 4, name: "User", coverNode: NodeEntity(handle: 3),
                               count: 1, type: .user, modificationTime: nil),
            selection: AlbumSelection())
        
        XCTAssertFalse(sut.isSelected)
        sut.onAlbumTap()
        XCTAssertTrue(sut.isSelected)
    }
    
    func testOnAlbumTap_whenUserTapOnAlbumCell_ShouldNotToggleForSystemAlbums() {
        let sut = AlbumCellViewModel(
            thumbnailUseCase: MockThumbnailUseCase(),
            album: AlbumEntity(id: 4, name: "Gif", coverNode: NodeEntity(handle: 3),
                               count: 1, type: .gif, modificationTime: nil),
            selection: AlbumSelection())
        
        XCTAssertFalse(sut.isSelected)
        sut.onAlbumTap()
        XCTAssertFalse(sut.isSelected)
    }
}
