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
    private var allViewModel: PhotoLibraryModeAllGridViewModel!
    
    private var testNodes: [NodeEntity] {
        get throws {
            [
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
        }
    }
    
    override func setUpWithError() throws {
        let library = try testNodes.toPhotoLibrary(withSortType: .newest, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library)
        libraryViewModel.selectedMode = .all
        allViewModel = PhotoLibraryModeAllGridViewModel(libraryViewModel: libraryViewModel)
    }
    
    func testInit_defaultValue() throws {
        let sut = PhotoCellViewModel(photo: NodeEntity(name: "0.jpg", handle: 0),
                                     viewModel: allViewModel,
                                     thumbnailUseCase: MockThumbnailUseCase(),
                                     mediaUseCase: MockMediaUseCase())
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image(FileTypes().fileType(forFileName: "0.jpg")), type: .placeholder)))
        XCTAssertEqual(sut.duration, "0:00")
        XCTAssertEqual(sut.isVideo, false)
        XCTAssertEqual(sut.currentZoomScaleFactor, .three)
        XCTAssertEqual(sut.isSelected, false)
        XCTAssertEqual(sut.isFavorite, false)
        XCTAssertNil(sut.thumbnailLoadingTask)
    }
    
    func testLoadThumbnail_zoomInAndHasCachedThumbnail_onlyLoadPreview() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail)],
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remoteURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(URLImageContainer(imageURL: remoteURL, type: .preview)))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertEqual(sut.currentZoomScaleFactor, .one)
        await sut.thumbnailLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remoteURL, type: .preview)))
    }
    
    func testLoadThumbnail_zoomOut_noLoadLocalThumbnailAndRemotePreview() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail)],
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remoteURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { _ in
                XCTFail("Thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        allViewModel.zoomState.zoom(.out)
        XCTAssertEqual(sut.currentZoomScaleFactor, .five)
        XCTAssertNil(sut.thumbnailLoadingTask)
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("Thumbnail should not be changed")
            return
        }
    }
    
    func testLoadThumbnail_hasCachedThumbnail_showThumbnailUponInit() async throws {
        let image = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isFileCreated = FileManager.default.createFile(atPath:url.path, contents: image.pngData())
        XCTAssertTrue(isFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: url, type: .thumbnail)]),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: url, type: .thumbnail)))
    }
    
    func testLoadThumbnail_hasDifferentThumbnailAndLoadThumbnail_noLoading() async throws {
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remoteURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remoteURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: remoteURL, type: .thumbnail))),
            mediaUseCase: MockMediaUseCase()
        )
        
        sut.thumbnailContainer = ImageContainer(image: Image(systemName: "heart"), type: .thumbnail)
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTFail("Thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        sut.startLoadingThumbnail()
        await sut.thumbnailLoadingTask?.value
        
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("Thumbnail should not be changed")
            return
        }
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image(systemName: "heart"), type: .thumbnail)))
    }
    
    func testLoadThumbnail_noThumbnails_showPlaceholder() async throws {
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("image"), type: .placeholder)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTFail("thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        sut.startLoadingThumbnail()
        await sut.thumbnailLoadingTask?.value
        
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("image"), type: .placeholder)))
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("thumbnail should not be changed")
            return
        }
    }
    
    func testLoadThumbnail_noCachedThumbnailAndNonSingleColumn_loadThumbnail() async throws {
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "eraser"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath:remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: remoteThumbnailURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("image"), type: .placeholder)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(URLImageContainer(imageURL: remoteThumbnailURL, type: .thumbnail)))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        XCTAssertEqual(sut.currentZoomScaleFactor, .three)
        sut.startLoadingThumbnail()
        await sut.thumbnailLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remoteThumbnailURL, type: .thumbnail)))
    }
    
    func testLoadThumbnail_noCachedThumbnailAndZoomInToSingleColumn_loadBothThumbnailAndPreview() async throws {
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "eraser"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath:remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: remoteThumbnailURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(ImageContainer(image: Image("image"), type: .placeholder)))
        
        let exp = expectation(description: "thumbnail is changed")
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
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertEqual(sut.currentZoomScaleFactor, .one)
        await sut.thumbnailLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remotePreviewURL, type: .preview)))
        XCTAssertTrue(expectedContainers.isEmpty)
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndNonSingleColumnAndSameRemoteThumbnail_noLoading() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail)],
                                                   loadThumbnailResult: .success(ThumbnailEntity(url: localURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTFail("thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        XCTAssertEqual(sut.currentZoomScaleFactor, .three)
        sut.startLoadingThumbnail()
        await sut.thumbnailLoadingTask?.value
        
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("thumbnail should not be changed")
            return
        }
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndNonSingleColumnAndDifferentRemoteThumbnail_noLoading() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "eraser"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath:remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail)],
                                                   loadThumbnailResult: .success(ThumbnailEntity(url: remoteThumbnailURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTFail("thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        XCTAssertEqual(sut.currentZoomScaleFactor, .three)
        sut.startLoadingThumbnail()
        await sut.thumbnailLoadingTask?.value
        
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("thumbnail should not be changed")
            return
        }
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndZoomInToSingleColumnAndSameRemoteThumbnail_onlyLoadPreview() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail)],
                                                   loadThumbnailResult: .success(ThumbnailEntity(url: localURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(URLImageContainer(imageURL: remotePreviewURL, type: .preview)))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertEqual(sut.currentZoomScaleFactor, .one)
        await sut.thumbnailLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remotePreviewURL, type: .preview)))
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndZoomInToSingleColumnAndDifferentRemoteThumbnail_loadBothThumbnailAndPreview() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "eraser"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath:remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail)],
                                                   loadThumbnailResult: .success(ThumbnailEntity(url: remoteThumbnailURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        
        let exp = expectation(description: "thumbnail is changed")
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
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertEqual(sut.currentZoomScaleFactor, .one)
        await sut.thumbnailLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: remotePreviewURL, type: .preview)))
        XCTAssertTrue(expectedContainers.isEmpty)
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndPreviewAndZoomInToSingleColumnAndSameRemoteThumbnailAndPreview_onlyLoadCachedPreview() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:previewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail),
                                                                      ThumbnailEntity(url: previewURL, type: .preview)],
                                                   loadThumbnailResult: .success(ThumbnailEntity(url: localURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: previewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(URLImageContainer(imageURL: previewURL, type: .preview)))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertEqual(sut.currentZoomScaleFactor, .one)
        await sut.thumbnailLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: previewURL, type: .preview)))
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndPreviewAndZoomInToSingleColumnAndDifferentRemoteThumbnailAndPreview_onlyLoadCachedPreview() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let localPreviewImage = try XCTUnwrap(UIImage(systemName: "doc"))
        let localPreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalPreviewFileCreated = FileManager.default.createFile(atPath:localPreviewURL.path, contents: localPreviewImage.pngData())
        XCTAssertTrue(isLocalPreviewFileCreated)
        
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "eraser"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath:remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .thumbnail),
                                                                      ThumbnailEntity(url: localPreviewURL, type: .preview)],
                                                   loadThumbnailResult: .success(ThumbnailEntity(url: remoteThumbnailURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .thumbnail)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTAssertTrue(container.isEqual(URLImageContainer(imageURL: localPreviewURL, type: .preview)))
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertEqual(sut.currentZoomScaleFactor, .one)
        await sut.thumbnailLoadingTask?.value
        wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localPreviewURL, type: .preview)))
    }
    
    func testLoadThumbnail_hasCachedPreviewAndSingleColumn_showPreviewAndNoLoading() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertTrue(allViewModel.zoomState.isSingleColumn)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localURL, type: .preview)],
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .preview)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTFail("thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        sut.startLoadingThumbnail()
        await sut.thumbnailLoadingTask?.value
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .preview)))
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("thumbnail should not be changed")
            return
        }
    }
    
    func testLoadThumbnail_hasCachedPreviewAndSingleColumnAndHasDifferentCachedPreview_noLoading() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let newLocalImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let newLocalURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isNewLocalFileCreated = FileManager.default.createFile(atPath:newLocalURL.path, contents: newLocalImage.pngData())
        XCTAssertTrue(isNewLocalFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.circle"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertTrue(allViewModel.zoomState.isSingleColumn)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: newLocalURL, type: .preview)],
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        sut.thumbnailContainer = try XCTUnwrap(URLImageContainer(imageURL: localURL, type: .preview))
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTFail("thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        sut.startLoadingThumbnail()
        await sut.thumbnailLoadingTask?.value
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localURL, type: .preview)))
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("thumbnail should not be changed")
            return
        }
    }
    
    func testLoadThumbnail_hasCachedThumbnailAndPreviewAndSingleColumn_showPreviewAndNoLoading() async throws {
        let localImage = try XCTUnwrap(UIImage(systemName: "folder"))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath:localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        let localPreviewImage = try XCTUnwrap(UIImage(systemName: "doc"))
        let localPreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalPreviewFileCreated = FileManager.default.createFile(atPath:localPreviewURL.path, contents: localPreviewImage.pngData())
        XCTAssertTrue(isLocalPreviewFileCreated)
        
        let remoteThumbnailImage = try XCTUnwrap(UIImage(systemName: "eraser"))
        let remoteThumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteThumbnailFileCreated = FileManager.default.createFile(atPath:remoteThumbnailURL.path, contents: remoteThumbnailImage.pngData())
        XCTAssertTrue(isRemoteThumbnailFileCreated)
        
        let remoteImage = try XCTUnwrap(UIImage(systemName: "folder.fill"))
        let remotePreviewURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isRemoteFileCreated = FileManager.default.createFile(atPath:remotePreviewURL.path, contents: remoteImage.pngData())
        XCTAssertTrue(isRemoteFileCreated)
        
        allViewModel.zoomState.zoom(.in)
        XCTAssertTrue(allViewModel.zoomState.isSingleColumn)
        
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: [ThumbnailEntity(url: localPreviewURL, type: .preview),
                                                                      ThumbnailEntity(url: localURL, type: .thumbnail)],
                                                   loadThumbnailResult: .success(ThumbnailEntity(url: remoteThumbnailURL, type: .thumbnail)),
                                                   loadPreviewResult: .success(ThumbnailEntity(url: remotePreviewURL, type: .preview))),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localPreviewURL, type: .preview)))
        
        let exp = expectation(description: "thumbnail is changed")
        sut.$thumbnailContainer
            .dropFirst()
            .sink { container in
                XCTFail("thumbnail should not be changed")
            }
            .store(in: &subscriptions)
        
        sut.startLoadingThumbnail()
        await sut.thumbnailLoadingTask?.value
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.thumbnailContainer.isEqual(URLImageContainer(imageURL: localPreviewURL, type: .preview)))
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("thumbnail should not be changed")
            return
        }
    }
    
    func testIsSelected_notSelectedAndSelect_selected() {
        let photo = NodeEntity(name: "0.jpg", handle: 0)
        let sut = PhotoCellViewModel(
            photo: photo,
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertFalse(sut.isSelected)
        XCTAssertFalse(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
        sut.isSelected = true
        XCTAssertTrue(sut.isSelected)
        XCTAssertTrue(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
    }
    
    func testIsSelected_selectedAndNonEditingDuringInit_isNotSelected() {
        let photo = NodeEntity(name: "0.jpg", handle: 0)
        allViewModel.libraryViewModel.selection.photos[0] = photo
        XCTAssertTrue(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
        
        let sut = PhotoCellViewModel(
            photo: photo,
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        XCTAssertFalse(sut.isSelected)
        XCTAssertTrue(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
    }
    
    func testIsSelected_selectedAndIsEditingDuringInit_selected() {
        let photo = NodeEntity(name: "0.jpg", handle: 0)
        allViewModel.libraryViewModel.selection.editMode = .active
        allViewModel.libraryViewModel.selection.photos[0] = photo
        XCTAssertTrue(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
        
        let sut = PhotoCellViewModel(
            photo: photo,
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        XCTAssertTrue(sut.isSelected)
        XCTAssertTrue(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
    }
    
    func testIsSelected_selectedAndDeselect_deselected() {
        let photo = NodeEntity(name: "0.jpg", handle: 0)
        allViewModel.libraryViewModel.selection.editMode = .active
        allViewModel.libraryViewModel.selection.photos[0] = photo
        XCTAssertTrue(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
        
        let sut = PhotoCellViewModel(
            photo: photo,
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        XCTAssertTrue(sut.isSelected)
        XCTAssertTrue(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
        
        sut.isSelected = false
        XCTAssertFalse(sut.isSelected)
        XCTAssertFalse(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
    }
    
    func testIsSelected_noSelectedAndSelectAll_selected() throws {
        let photo = NodeEntity(name: "0.jpg", handle: 0)
        let sut = PhotoCellViewModel(
            photo: photo,
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        
        XCTAssertFalse(sut.isSelected)
        XCTAssertFalse(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
        XCTAssertFalse(allViewModel.libraryViewModel.selection.allSelected)
        
        allViewModel.libraryViewModel.selection.allSelected = true
        allViewModel.libraryViewModel.selection.setSelectedPhotos(try testNodes)
        
        XCTAssertTrue(sut.isSelected)
        XCTAssertTrue(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
    }
    
    func testIsSelected_selectedAndDeselectAll_notSelected() throws {
        let photo = NodeEntity(name: "0.jpg", handle: 0)
        
        allViewModel.libraryViewModel.selection.editMode = .active
        allViewModel.libraryViewModel.selection.allSelected = true
        allViewModel.libraryViewModel.selection.setSelectedPhotos(try testNodes)
        XCTAssertTrue(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
        XCTAssertTrue(allViewModel.libraryViewModel.selection.allSelected)
        
        let sut = PhotoCellViewModel(
            photo: photo,
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        
        allViewModel.libraryViewModel.selection.allSelected = false
        XCTAssertFalse(sut.isSelected)
        XCTAssertFalse(allViewModel.libraryViewModel.selection.isPhotoSelected(photo))
    }
    
    func testIsFavorite_isNotFavoriteAndReceiveFavoriteUpdate_isFavorite() {
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        XCTAssertFalse(sut.isFavorite)
        
        let exp = expectation(description: "isFavourite is updated")
        sut.$isFavorite
            .dropFirst()
            .sink { isFavorite in
                XCTAssertTrue(isFavorite)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default.post(name: .didPhotoFavouritesChange,
                                        object: [NodeEntity(name: "0.jpg", handle: 0, isFavourite: true)])
        wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(sut.isFavorite)
    }
    
    func testIsFavorite_isFavoriteAndReceiveNotFavoriteUpdate_isNotFavorite() {
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0, isFavourite: true),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        XCTAssertTrue(sut.isFavorite)
        
        let exp = expectation(description: "isFavourite is updated")
        sut.$isFavorite
            .dropFirst()
            .sink { isFavorite in
                XCTAssertFalse(isFavorite)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default.post(name: .didPhotoFavouritesChange,
                                        object: [NodeEntity(name: "0.jpg", handle: 0, isFavourite: false)])
        wait(for: [exp], timeout: 2.0)
        XCTAssertFalse(sut.isFavorite)
    }
    
    func testIsFavorite_isNotFavoriteAndReceiveNoUpdates_isNotFavorite() {
        let sut = PhotoCellViewModel(
            photo: NodeEntity(name: "0.jpg", handle: 0),
            viewModel: allViewModel,
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        XCTAssertFalse(sut.isFavorite)
        
        let exp = expectation(description: "isFavourite is updated")
        sut.$isFavorite
            .dropFirst()
            .sink { isFavorite in
                XCTFail("isFavourite should not be updated")
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default.post(name: .didPhotoFavouritesChange,
                                        object: [NodeEntity(name: "00.jpg", handle: 1, isFavourite: true)])
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        XCTAssertFalse(sut.isFavorite)
        guard case XCTWaiter.Result.timedOut = result else {
            XCTFail("isFavourite should not be updated")
            return
        }
    }
    
    func testShouldShowEditState_editing() {
        let sut = PhotoCellViewModel(photo: NodeEntity(handle: 1),
                                     viewModel: allViewModel,
                                     thumbnailUseCase: MockThumbnailUseCase(),
                                     mediaUseCase: MockMediaUseCase())
        sut.editMode = .active
        
        for scaleFactor in PhotoLibraryZoomState.ScaleFactor.allCases {
            sut.currentZoomScaleFactor = scaleFactor
            XCTAssertEqual(sut.shouldShowEditState, scaleFactor != .thirteen)
        }
    }
    
    func testShouldShowEditState_notEditing() {
        let sut = PhotoCellViewModel(photo: NodeEntity(handle: 1),
                                     viewModel: allViewModel,
                                     thumbnailUseCase: MockThumbnailUseCase(),
                                     mediaUseCase: MockMediaUseCase())
        sut.editMode = .inactive
        
        for scaleFactor in PhotoLibraryZoomState.ScaleFactor.allCases {
            sut.currentZoomScaleFactor = scaleFactor
            XCTAssertFalse(sut.shouldShowEditState)
        }
    }
    
    func testShouldShowFavorite_favourite() {
        let sut = PhotoCellViewModel(photo: NodeEntity(handle: 1),
                                     viewModel: allViewModel,
                                     thumbnailUseCase: MockThumbnailUseCase(),
                                     mediaUseCase: MockMediaUseCase())
        sut.isFavorite = true
        
        for scaleFactor in PhotoLibraryZoomState.ScaleFactor.allCases {
            sut.currentZoomScaleFactor = scaleFactor
            XCTAssertEqual(sut.shouldShowFavorite, scaleFactor != .thirteen)
        }
    }
    
    func testShouldShowFavorite_notFavourite() {
        let sut = PhotoCellViewModel(photo: NodeEntity(handle: 1),
                                     viewModel: allViewModel,
                                     thumbnailUseCase: MockThumbnailUseCase(),
                                     mediaUseCase: MockMediaUseCase())
        sut.isFavorite = false
        
        for scaleFactor in PhotoLibraryZoomState.ScaleFactor.allCases {
            sut.currentZoomScaleFactor = scaleFactor
            XCTAssertFalse(sut.shouldShowFavorite)
        }
    }
    
    func testSelect_onEditModeNoLimitConfigured_shouldChangeIsSelectedOnCellTap() throws {
        let sut = PhotoCellViewModel(photo: NodeEntity(handle: 1),
                                     viewModel: allViewModel,
                                     thumbnailUseCase: MockThumbnailUseCase(),
                                     mediaUseCase: MockMediaUseCase())
        allViewModel.libraryViewModel.selection.editMode = .active
        XCTAssertFalse(sut.isSelected)
        sut.select()
        XCTAssertTrue(sut.isSelected)
    }
    
    func testSelect_onEditModeAndLimitConfigured_shouldChangeIsSelectedOnCellTap() throws {
        let selectionLimit = 3
        let library = try testNodes.toPhotoLibrary(withSortType: .newest, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library, selectLimit: selectionLimit)
        libraryViewModel.selectedMode = .all
        
        let photo = NodeEntity(name: "0.jpg", handle: 0)
        let sut = PhotoCellViewModel(
            photo: photo,
            viewModel: PhotoLibraryModeAllGridViewModel(libraryViewModel: libraryViewModel),
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        libraryViewModel.selection.editMode = .active
        XCTAssertFalse(sut.isSelected)
        sut.select()
        XCTAssertTrue(sut.isSelected)
    }
    
    func testSelect_onEditModeItemNotSelectedAndLimitReached_shouldNotChangeIsSelectedOnCellTap() throws {
        let selectionLimit = 3
        let library = try testNodes.toPhotoLibrary(withSortType: .newest, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library, selectLimit: selectionLimit)
        libraryViewModel.selectedMode = .all
        
        let photo = NodeEntity(name: "0.jpg", handle: 0)
        let sut = PhotoCellViewModel(
            photo: photo,
            viewModel: PhotoLibraryModeAllGridViewModel(libraryViewModel: libraryViewModel),
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        libraryViewModel.selection.editMode = .active
        XCTAssertFalse(sut.isSelected)
        let photosToSelect = Array(library.allPhotos.filter { $0 != photo }.prefix(selectionLimit))
        libraryViewModel.selection.setSelectedPhotos(photosToSelect)
        sut.select()
        XCTAssertFalse(sut.isSelected)
    }
    
    func testShouldApplyContentOpacity_onEditModeItemIsNotSelectedAndLimitReached_shouldChangeContentOpacity() throws {
        let selectionLimit = 3
        let library = try testNodes.toPhotoLibrary(withSortType: .newest, in: .GMT)
        let libraryViewModel = PhotoLibraryContentViewModel(library: library, selectLimit: selectionLimit)
        libraryViewModel.selectedMode = .all
        
        let photo = NodeEntity(name: "0.jpg", handle: 0)
        let sut = PhotoCellViewModel(
            photo: photo,
            viewModel: PhotoLibraryModeAllGridViewModel(libraryViewModel: libraryViewModel),
            thumbnailUseCase: MockThumbnailUseCase(),
            mediaUseCase: MockMediaUseCase()
        )
        XCTAssertFalse(sut.shouldApplyContentOpacity)
        sut.editMode = .active
        sut.isSelected = false
        libraryViewModel.selection.setSelectedPhotos(Array(try testNodes.suffix(selectionLimit)))
        XCTAssertTrue(sut.shouldApplyContentOpacity)
        sut.editMode = .inactive
        XCTAssertFalse(sut.shouldApplyContentOpacity)
    }
}
