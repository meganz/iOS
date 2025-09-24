import Foundation
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASdk
import Testing
import UIKit

struct AlbumLinkThumbnailRepositoryTests {
    private let thumbnailURL = URL(string: "https://mega.io")
    
    @Test(.disabled("Disabled due to flakiness"))
    func loadThumbnailFileNotCreated() async throws {
        let base64Handle = "base64Handle"
        let node = MockNode(handle: 4, nodeBase64Handle: base64Handle, hasThumbnail: true)
        let nodeEntity = node.toNodeEntity()
        let nodeProvider = MockMEGANodeProvider(node: node)
        let imagePath = try Self.makeImagePathURL(base64Handle: base64Handle).path
        Self.makeFile(path: imagePath, contents: UIImage(systemName: "folder")?.pngData())
        
        let sut = Self.makeSUT(
            nodeProvider: nodeProvider,
            sdk: MockSdk(file: imagePath)
        )
        
        let imagePathURLForNodeEntity = try await sut.loadThumbnail(
            for: nodeEntity, type: .thumbnail)
        let imagePathURLForNodeHandle = try await sut.loadThumbnail(
            for: nodeEntity.handle, type: .thumbnail)
        let expectedURL = try #require(URL(string: imagePath))
        #expect(imagePathURLForNodeEntity == expectedURL)
        #expect(imagePathURLForNodeHandle == expectedURL)
        try Self.removeFile(path: imagePath)
    }
    
    @Test func cachedThumbnail() throws {
        let sut = Self.makeSUT(
            thumbnailRepository: MockThumbnailRepository(
                cachedThumbnailURLs: [(ThumbnailTypeEntity.thumbnail, thumbnailURL)]
            ))
        let node = NodeEntity(handle: 1)
        
        #expect(sut.cachedThumbnail(for: node, type: .thumbnail) == thumbnailURL)
        #expect(sut.cachedThumbnail(for: node.handle, type: .thumbnail) == thumbnailURL)
    }
    
    @Test
    func generateCachingURL() throws {
        let sut = Self.makeSUT(
            thumbnailRepository: MockThumbnailRepository(
                cachedThumbnailURL: try #require(thumbnailURL)))
        
        let node = NodeEntity(handle: 1, base64Handle: "base64Handle")
        #expect(sut.generateCachingURL(for: node, type: .thumbnail) == thumbnailURL)
        #expect(sut.generateCachingURL(for: node.base64Handle, type: .thumbnail) == thumbnailURL)
    }

    static func makeSUT(
        thumbnailRepository: some ThumbnailRepositoryProtocol = MockThumbnailRepository(),
        nodeProvider: some MEGANodeProviderProtocol = MockMEGANodeProvider(),
        sdk: MEGASdk = MockSdk(),
        fileManager: FileManager = .default,
    ) -> AlbumLinkThumbnailRepository {
        .init(
            thumbnailRepository: thumbnailRepository,
            nodeProvider: nodeProvider,
            sdk: sdk,
            fileManager: fileManager
        )
    }
    
    private static func makeImagePathURL(
        fileManager: FileManager = .default,
        directory: String = "thumbnailsV3",
        base64Handle: String
    ) throws -> URL {
        AppGroupContainer(fileManager: fileManager)
            .url(for: .cache)
            .appendingPathComponent(directory, isDirectory: true)
            .appendingPathComponent(base64Handle)
    }
    
    private static func makeFile(path: String, contents: Data?) {
        #expect(FileManager.default.createFile(atPath: path, contents: contents))
    }
    
    private static func removeFile(path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }
}
