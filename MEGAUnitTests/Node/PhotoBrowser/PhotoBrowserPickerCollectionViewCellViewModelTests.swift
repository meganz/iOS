@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

struct PhotoBrowserPickerCollectionViewCellViewModelTests {

    @MainActor
    @Suite("init")
    struct Constructor {
        @Test(arguments: [true, false])
        func hasThumbnail(hasThumbnail: Bool) {
            let sut = makeSUT(node: .init(handle: 1, hasThumbnail: hasThumbnail))
            
            #expect(sut.hasThumbnail == hasThumbnail)
        }
    
        @Test(arguments: [("image.jpg", false), ("video.mp4", true)])
        func isVideo(fileName: String, isVideo: Bool) {
            let sut = makeSUT(node: .init(name: fileName, handle: 1))
            
            #expect(sut.isVideo == isVideo)
        }
    }
    
    @MainActor
    @Test(arguments: [(60, "01:00"), (-1, "")])
    func videoDuration(duration: Int, expected: String) {
        let sut = Self.makeSUT(node: .init(
            name: "test.mp4", handle: 1, duration: duration))
        
        #expect(sut.videoDuration == expected)
    }
    
    @MainActor
    @Suite("ConfigureCell")
    struct ConfigureCell {
        @MainActor
        @Suite("Sensitive")
        struct Sensitive {
            @Test("If from shared item it should not apply sensitive")
            func isFromSharedItem() async {
                let sut = makeSUT(isFromSharedItem: true)
                #expect(sut.isSensitive == false)
                
                await sut.configureCell().value
                
                #expect(sut.isSensitive == false)
            }
            
            @Test func isAccessible() async throws {
                let sut = makeSUT(
                    sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                        isAccessible: false
                    ))
                
                #expect(sut.isSensitive == false)
                
                await sut.configureCell().value
                
                #expect(sut.isSensitive == false)
            }
            
            @Test
            func nodeMarkedSensitive() async {
                let sut = makeSUT(node: .init(isMarkedSensitive: true))
                
                await sut.configureCell().value
                
                #expect(sut.isSensitive)
            }
            
            @Test(arguments: [true, false])
            func inheritedSensitivity(isSensitive: Bool) async {
                let sut = makeSUT(
                    node: .init(isMarkedSensitive: false),
                    sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(isSensitive)))
                
                await sut.configureCell().value
                
                #expect(sut.isSensitive == isSensitive)
            }
        }
        
        @MainActor
        @Suite
        struct Thumbnail {
            @Test("No thumbnail should return icon")
            func noThumbnail() async {
                let nodeIconUseCase = MockNodeIconUsecase()
                let sut = makeSUT(
                    node: .init(hasThumbnail: false),
                    nodeIconUseCase: nodeIconUseCase)
                
                await sut.configureCell().value
                
                #expect(nodeIconUseCase.invocations == [.iconData])
            }
            
            @Test
            func cachedThumbnail() async throws {
                let imageURL = try makeImageURL()
                let thumbnailUseCase = MockThumbnailUseCase(
                    cachedThumbnails: [.init(url: imageURL, type: .thumbnail)]
                )
                let sut = makeSUT(
                    node: .init(hasThumbnail: true),
                    thumbnailUseCase: thumbnailUseCase)
                
                await sut.configureCell().value
                
                #expect(sut.thumbnail?.pngData() == UIImage(contentsOfFile: imageURL.path())?.pngData())
                
                try FileManager.default.removeItem(atPath: imageURL.path)
            }
            
            @Test
            func loadThumbnail() async throws {
                let imageURL = try makeImageURL()
                let thumbnailUseCase = MockThumbnailUseCase(
                    loadThumbnailResult: .success(.init(url: imageURL, type: .thumbnail))
                )
                let nodeIconUseCase = MockNodeIconUsecase()
                let sut = makeSUT(
                    node: .init(hasThumbnail: true),
                    thumbnailUseCase: thumbnailUseCase,
                    nodeIconUseCase: nodeIconUseCase)
                
                await sut.configureCell().value
                
                #expect(nodeIconUseCase.invocations == [.iconData])
                #expect(sut.thumbnail?.pngData() == UIImage(contentsOfFile: imageURL.path())?.pngData())
                
                try FileManager.default.removeItem(atPath: imageURL.path)
            }
            
            private func makeImageURL() throws -> URL {
                let localImage = try #require(UIImage(systemName: "folder"))
                let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
                #expect(FileManager.default.createFile(atPath: localURL.path, contents: localImage.pngData()))
                return localURL
            }
        }
    }

    @MainActor
    private static func makeSUT(
        node: NodeEntity? = nil,
        isFromSharedItem: Bool = false,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        thumbnailUseCase: some ThumbnailUseCaseProtocol = MockThumbnailUseCase(),
        nodeIconUseCase: some NodeIconUsecaseProtocol = MockNodeIconUsecase(),
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
    ) -> PhotoBrowserPickerCollectionViewCellViewModel {
        .init(node: node,
              isFromSharedItem: isFromSharedItem,
              sensitiveNodeUseCase: sensitiveNodeUseCase,
              thumbnailUseCase: thumbnailUseCase,
              nodeIconUseCase: nodeIconUseCase,
              remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
    }
}
