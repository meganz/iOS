import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import XCTest

final class ThumbnailRepositoryTests: XCTestCase {
    
    func testCachedThumbnail_onNoFileCached_shouldReturnNil() {
        let node = NodeEntity(handle: 1, base64Handle: "node_1_base_64_thumbnail")
        let sut = makeThumbnailRepository()
        XCTAssertNil(sut.cachedThumbnail(for: node, type: .thumbnail))
    }
    
    func testCachedThumbnail_forType_shouldReturnCorrectURL() throws {
        let node = NodeEntity(handle: 5, base64Handle: "node_5_base_64_thumbnail")
        let imageURL = try makeImageFile(forNode: node, type: .thumbnail)
        
        let sut = makeThumbnailRepository()
        let result = sut.cachedThumbnail(for: node, type: .thumbnail)
        XCTAssertEqual(result, imageURL)
    }
    
    func testLoadThumbnail_withCachedFile_shouldReturnCachedURL() async throws {
        let node = NodeEntity(handle: 5, base64Handle: "node_5_base_64_thumbnail")
        let imageURL = try makeImageFile(forNode: node, type: .thumbnail)
        
        let sut = makeThumbnailRepository()
        
        let result = try await sut.loadThumbnail(for: node, type: .thumbnail)
        
        XCTAssertEqual(result, imageURL)
    }
    
    func testLoadThumbnail_onNonCachedFile_shouldDownloadToDirectory() async throws {
        let node = NodeEntity(handle: 4, base64Handle: "node_4_not_cached_base_64_thumbnail",
                              hasThumbnail: true)
        let megaNode = MockNode(handle: 4, hasThumbnail: true)
        let thumbnailFilePath = try imagePathURL(forNode: node, type: .thumbnail).path
        
        let sdk = MockSdk(file: thumbnailFilePath)
        let nodeProvider = MockMEGANodeProvider(node: megaNode)
        let sut = makeThumbnailRepository(sdk: sdk, nodeProvider: nodeProvider)
        
        let result = try await sut.loadThumbnail(for: node, type: .thumbnail)
        
        XCTAssertEqual(result, URL(string: thumbnailFilePath))
    }
    
    func testLoadThumbnail_megaNodeCouldNotBeConverted_shouldThrowError() async {
        let node = NodeEntity(handle: 4, base64Handle: "invalid")
        let sut = makeThumbnailRepository()
        
        do {
            _ = try await sut.loadThumbnail(for: node, type: .thumbnail)
            XCTFail("Should have thrown error")
        } catch let error as ThumbnailErrorEntity {
            XCTAssertEqual(error, ThumbnailErrorEntity.nodeNotFound)
        } catch {
            XCTFail("Invalid error thrown")
        }
    }
    
    func testLoadThumbnail_nodeWithOutThumbnail_shouldThrowError() async {
        let node = NodeEntity(handle: 4, base64Handle: "invalid")
        let nodeProvider = MockMEGANodeProvider(node: MockNode(handle: node.handle))
        let sut = makeThumbnailRepository(nodeProvider: nodeProvider)
        
        do {
            _ = try await sut.loadThumbnail(for: node, type: .thumbnail)
            XCTFail("Should have thrown error")
        } catch let error as ThumbnailErrorEntity {
            XCTAssertEqual(error, ThumbnailErrorEntity.noThumbnail(.thumbnail))
        } catch {
            XCTFail("Invalid error thrown")
        }
    }
    
    func testLoadThumbnail_downloadOfThumbnailFailsApiENoent_shouldThrowNoThumbnailError() async {
        let node = NodeEntity(handle: 4, base64Handle: "valid")
        let sdk = MockSdk(megaSetError: .apiENoent)
        let nodeProvider = MockMEGANodeProvider(node: MockNode(handle: node.handle, hasThumbnail: true))
        let sut = makeThumbnailRepository(sdk: sdk, nodeProvider: nodeProvider)
        
        do {
            _ = try await sut.loadThumbnail(for: node, type: .thumbnail)
            XCTFail("Should have thrown error")
        } catch let error as ThumbnailErrorEntity {
            XCTAssertEqual(error, .noThumbnail(.thumbnail))
        } catch {
            XCTFail("Invalid error thrown")
        }
    }
    
    func testLoadThumbnail_downloadOfThumbnailFailsWithOtherError_shouldThrowGenericError() async {
        let node = NodeEntity(handle: 4, base64Handle: "valid")
        let sdk = MockSdk(megaSetError: .apiEFailed)
        let nodeProvider = MockMEGANodeProvider(node: MockNode(handle: node.handle, hasThumbnail: true))
        let sut = makeThumbnailRepository(sdk: sdk, nodeProvider: nodeProvider)
        
        do {
            _ = try await sut.loadThumbnail(for: node, type: .thumbnail)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity)
        }
    }
    
    func testLoadThumbnail_invalidURL_shouldThrowGenericError() async {
        let node = NodeEntity(handle: 4, base64Handle: "valid",
                              hasThumbnail: true)
        let megaNode = MockNode(handle: 4, hasThumbnail: true)
        
        let sdk = MockSdk(file: "")
        let nodeProvider = MockMEGANodeProvider(node: megaNode)
        let sut = makeThumbnailRepository(sdk: sdk, nodeProvider: nodeProvider)
        
        do {
            _ = try await sut.loadThumbnail(for: node, type: .thumbnail)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity)
        }
    }
    
    func testLoadThumbnail_withPreviewType_shouldDownloadPreview() async throws {
        let node = NodeEntity(handle: 4, base64Handle: "node_5_preview_not_cached",
                              hasThumbnail: true)
        let megaNode = MockNode(handle: 4, hasPreview: true)
        let previewFilePath = try imagePathURL(forNode: node, type: .preview).path
        
        let sdk = MockSdk(file: previewFilePath)
        let nodeProvider = MockMEGANodeProvider(node: megaNode)
        let sut = makeThumbnailRepository(sdk: sdk, nodeProvider: nodeProvider)
        
        let result = try await sut.loadThumbnail(for: node, type: .preview)
        
        XCTAssertEqual(result, URL(string: previewFilePath))
    }
    
    func testLoadThumbnail_withPreviewTypeNoPreview_shouldThrowNoThumbnailPreview() async throws {
        let node = NodeEntity(handle: 4, base64Handle: "node_5_preview_not_cached",
                              hasThumbnail: true)
        let megaNode = MockNode(handle: 4, hasPreview: false)
        let nodeProvider = MockMEGANodeProvider(node: megaNode)
        let sut = makeThumbnailRepository(nodeProvider: nodeProvider)
        do {
            _ = try await sut.loadThumbnail(for: node, type: .preview)
            XCTFail("Should have thrown error")
        } catch let error as ThumbnailErrorEntity {
            XCTAssertEqual(error, .noThumbnail(.preview))
        } catch {
            XCTFail("Invalid error thrown")
        }
    }
    
    func testLoadThumbnail_withOriginal_shouldLoadURL() async throws {
        let node = NodeEntity(handle: 4, base64Handle: "node_5_original_not_cached")
        let megaNode = MockNode(handle: 4, hasPreview: true)
        let orignalImagePath = try imagePathURL(forNode: node, type: .original).path
        
        let sdk = MockSdk(file: orignalImagePath)
        let nodeProvider = MockMEGANodeProvider(node: megaNode)
        let sut = makeThumbnailRepository(sdk: sdk, nodeProvider: nodeProvider)
        
        let result = try await sut.loadThumbnail(for: node, type: .original)
        
        XCTAssertEqual(result, URL(string: orignalImagePath))
    }
    
    func testCachedPreviewOrOriginalPath_forNoFileCached_shouldReturnNil() {
        let node = NodeEntity(handle: 1, base64Handle: "dont_exist")
        let sut = makeThumbnailRepository()
        XCTAssertNil(sut.cachedPreviewOrOriginalPath(for: node))
    }
    
    func testCachedPreviewOrOriginalPath_forCachedPreview_shouldReturnPreviewURL() throws {
        let node = NodeEntity(handle: 9, base64Handle: "node_9")
        let previewImageURL = try makeImageFile(forNode: node, type: .preview)
        
        let sut = makeThumbnailRepository()
        let cachedPath = sut.cachedPreviewOrOriginalPath(for: node)
        XCTAssertEqual(cachedPath, previewImageURL.path)
    }
    
    func testCachedPreviewOrOriginalPath_forCachedOrignal_shouldReturnOriginalURLWithFileName() throws {
        let fileName = "fileName.png"
        let node = NodeEntity(name: fileName, handle: 10, base64Handle: "node_10")
        let originalImageURL = try makeImageFile(forNode: node, type: .original)
        
        let sut = makeThumbnailRepository()
        let cachedPath = sut.cachedPreviewOrOriginalPath(for: node)
        XCTAssertEqual(cachedPath, originalImageURL.appendingPathComponent(fileName).path)
    }
    
    // MARK: Private
    
    private func makeThumbnailRepository(sdk: MEGASdk = MockSdk(),
                                         fileManager: FileManager = .default,
                                         nodeProvider: any MEGANodeProviderProtocol = MockMEGANodeProvider()) -> ThumbnailRepository {
        ThumbnailRepository(sdk: sdk,
                            fileManager: fileManager, nodeProvider: nodeProvider)
    }
    
    private func makeImageFile(forNode node: NodeEntity, image: UIImage? = UIImage(systemName: "folder"), type: ThumbnailTypeEntity) throws -> URL {
        let localImage = try XCTUnwrap(image)
        let imageNodeURL = try imagePathURL(forNode: node, type: type)
        makeFile(path: imageNodeURL.path, contents: localImage.pngData())
        return imageNodeURL
    }
    
    private func imagePathURL(forNode node: NodeEntity, type: ThumbnailTypeEntity) throws -> URL {
        switch type {
        case .thumbnail:
            return try makeThumbnailCacheDirectoryURL()
                .appendingPathComponent(node.base64Handle)
        case .preview:
            return try makePreviewCacheDirectoryURL()
                .appendingPathComponent(node.base64Handle)
        case .original:
            return try makeOriginalCacheDirectoryURL()
                .appendingPathComponent(node.base64Handle)
        }
    }
    
    private func makeThumbnailCacheDirectoryURL() throws -> URL {
        try makeCacheDirectoryURL(directory: "thumbnailsV3")
    }
    
    private func makePreviewCacheDirectoryURL() throws -> URL {
        try makeCacheDirectoryURL(directory: "previewsV3")
    }
    
    private func makeOriginalCacheDirectoryURL() throws -> URL {
        try makeCacheDirectoryURL(directory: "originalV3")
    }
    
    private func makeCacheDirectoryURL(directory: String) throws -> URL {
        return AppGroupContainer(fileManager: .default).url(for: .cache)
            .appendingPathComponent(directory, isDirectory: true)
    }
    
    private func makeFile(path: String, contents: Data?) {
        let isLocalFileCreated = FileManager.default.createFile(atPath: path, contents: contents)
        XCTAssertTrue(isLocalFileCreated)
    }
}
