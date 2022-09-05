import XCTest
import SwiftUI
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwiftUI
import MEGAFoundation
import Combine

final class PhotoCellViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    private var allViewModel: PhotoLibraryAllViewModel!

    override func setUpWithError() throws {
        let nodes =  [
            NodeEntity(name: "00.jpg", handle: 100, modificationTime: try "2022-09-03T22:01:04Z".date),
            NodeEntity(name: "0.jpg", handle: 0, modificationTime: try "2022-09-01T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 1, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "a.jpg", handle: 2, modificationTime: try "2022-08-10T22:01:04Z".date),
            NodeEntity(name: "b.jpg", handle: 3, modificationTime: try "2020-04-18T20:01:04Z".date),
            NodeEntity(name: "c.mov", handle: 4, modificationTime: try "2020-04-18T12:01:04Z".date),
            NodeEntity(name: "d.mp4", handle: 5, modificationTime: try "2020-04-18T01:01:04Z".date),
            NodeEntity(name: "e.mp4", handle: 6, modificationTime: try "2019-10-18T01:01:04Z".date),
            NodeEntity(name: "f.mp4", handle: 7, modificationTime: try "2018-01-23T01:01:04Z".date),
            NodeEntity(name: "g.mp4", handle: 8, modificationTime: try "2017-12-31T01:01:04Z".date),
        ]
        let library = nodes.toPhotoLibrary(withSortType: .newest, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .all
        allViewModel = PhotoLibraryAllViewModel(libraryViewModel: libraryViewModel)
    }

    func testInit_defaultValue() throws {
        let sut = PhotoCellViewModel(photo: NodeEntity(name: "0.jpg", handle: 0),
                                     viewModel: allViewModel,
                                     thumbnailUseCase: MockThumbnailUseCase())
        
        XCTAssertEqual(sut.thumbnailContainer,
                       ImageContainer(image: Image(FileTypes().fileType(forFileName: "0.jpg")), isPlaceholder: true))
        XCTAssertEqual(sut.duration, "00:00")
        XCTAssertEqual(sut.isVideo, false)
        XCTAssertEqual(sut.currentZoomScaleFactor, 3)
        XCTAssertEqual(sut.isSelected, false)
        XCTAssertEqual(sut.isFavorite, false)
        XCTAssertNil(sut.thumbnailLoadingTask)
    }
    
    func testLoadThumbnail_zoomInAndHasCachedThumbnail_loadLocalThumbnailAndRemotePreview() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID())_local", isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent("\((UUID()))_remote", isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnailURL: localURL, loadPreviewResult: .success(remoteURL))
        )
        
        let thumbnailChangeExpectation = XCTestExpectation(description: "thumbnail is changed")
        thumbnailChangeExpectation.expectedFulfillmentCount = 2
        var thumbnails = [URLImageContainer(imageURL: localURL), URLImageContainer(imageURL: remoteURL)]
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertEqual(container, thumbnails.removeFirst())
                thumbnailChangeExpectation.fulfill()
            }
            .store(in: &subscriptions)
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertEqual(sut.currentZoomScaleFactor, 1)
        await sut.thumbnailLoadingTask?.value
        wait(for: [thumbnailChangeExpectation], timeout: 1.0)
        XCTAssertTrue(thumbnails.isEmpty)
    }
    
    func testLoadThumbnail_zoomOut_noLoadLocalThumbnailAndRemotePreview() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("\((UUID()))_local", isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent("\((UUID()))_remote", isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnailURL: localURL, loadPreviewResult: .success(remoteURL))
        )
        
        let thumbnailChangeExpectation = XCTestExpectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { _ in
                XCTFail("Thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        allViewModel.zoomState.zoom(.out)
        XCTAssertEqual(sut.currentZoomScaleFactor, 5)
        XCTAssertNil(sut.thumbnailLoadingTask)
        let result = XCTWaiter.wait(for: [thumbnailChangeExpectation], timeout: 1.0)
        print("result: \(result)")
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("Thumbnail should not be changed")
            return
        }
    }
    
    func testLoadThumbnail_placeholderAndLoadThumbnail_loadThumbnail() async throws {
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent("\((UUID()))_remote", isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(remoteURL))
        )
        
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertEqual(container, URLImageContainer(imageURL: remoteURL))
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnailIfNeeded()
        await sut.thumbnailLoadingTask?.value
        XCTAssertEqual(sut.thumbnailContainer, URLImageContainer(imageURL: remoteURL))
    }
    
    func testLoadThumbnail_nonPlaceholderAndLoadThumbnail_noLoadThumbnail() async throws {
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent("\((UUID()))_remote", isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(remoteURL))
        )
        
        sut.thumbnailContainer = ImageContainer(image: Image(systemName: "heart"))
        
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTFail("Thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        sut.loadThumbnailIfNeeded()
        await sut.thumbnailLoadingTask?.value
        XCTAssertEqual(sut.thumbnailContainer, ImageContainer(image: Image(systemName: "heart")))
    }
}
