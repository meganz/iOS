@testable import MEGA
import MEGAAppSDKRepoMock
import MEGASdk
import Testing

@Suite("StreamingInfoRepository")
struct StreamingInfoRepositoryTests {
    static let defaultName = "any-name"
    static let localURL = URL(string: "http://127.0.0.1:4443/file")!
    static let defaultPort = 4443
    
    private static func makeSUT(sdk: MockSdk) -> StreamingInfoRepository {
        StreamingInfoRepository(sdk: sdk)
    }
    
    private static func makeNode(
        _ handle: UInt64 = 1,
        name: String? = nil,
        hasThumb: Bool = true
    ) -> MockNode {
        MockNode(
            handle: handle,
            name: name ?? defaultName,
            hasThumbnail: hasThumb
        )
    }
    
    private static func makeSdk(
        nodes: [MEGANode] = [],
        localLink: URL? = nil,
        isLocalOnly: Bool = true,
        isRunning: Bool = false,
        updatedAddressURL: URL? = nil
    ) -> MockSdk {
        MockSdk(
            nodes: nodes,
            localLink: localLink,
            isLocalOnly: isLocalOnly,
            isRunning: isRunning,
            updatedAddressURL: updatedAddressURL
        )
    }
    
    @Suite("Server lifecycle")
    struct ServerLifecycle {
        @Test("serverStart starts the HTTP server")
        func serverStart_startsHttpServer() {
            let sdk = StreamingInfoRepositoryTests.makeSdk()
            let sut = StreamingInfoRepositoryTests.makeSUT(sdk: sdk)
            
            sut.serverStart()
            
            #expect(sdk.httpServerStart_calledTimes == 1)
        }
        
        @Test("serverStart sets localOnly = false")
        func serverStart_setsLocalOnlyFalse() {
            let sdk = StreamingInfoRepositoryTests.makeSdk()
            let sut = StreamingInfoRepositoryTests.makeSUT(sdk: sdk)
            
            sut.serverStart()
            
            #expect(sdk.httpServerStart_lastArgs?.localOnly == false)
        }
        
        @Test("serverStart uses default port")
        func serverStart_usesDefaultPort() {
            let sdk = StreamingInfoRepositoryTests.makeSdk()
            let sut = StreamingInfoRepositoryTests.makeSUT(sdk: sdk)
            
            sut.serverStart()
            
            #expect(sdk.httpServerStart_lastArgs?.port == StreamingInfoRepositoryTests.defaultPort)
        }
        
        @Test("serverStop stops the HTTP server")
        func serverStop_stopsHttpServer() {
            let sdk = StreamingInfoRepositoryTests.makeSdk()
            let sut = StreamingInfoRepositoryTests.makeSUT(sdk: sdk)
            
            sut.serverStop()
            
            #expect(sdk.httpServerStop_calledTimes == 1)
        }
    }
    
    @Suite("Folder link → info")
    struct FolderLinkInfo {
        @Test(
            "returns nil when node invalid or link missing",
            arguments: [
                (node: MEGANode(), sdk: StreamingInfoRepositoryTests.makeSdk(localLink: StreamingInfoRepositoryTests.localURL)),
                (node: StreamingInfoRepositoryTests.makeNode(), sdk: StreamingInfoRepositoryTests.makeSdk(localLink: nil))
            ]
        )
        func infoReturnsNil(args: (node: MEGANode, sdk: MockSdk)) {
            let sut = StreamingInfoRepositoryTests.makeSUT(sdk: args.sdk)
            #expect(sut.fetchTrack(from: args.node) == nil)
        }
        
        @Test("valid node with link returns non-nil item")
        func validNode_withLink_returnsItem() {
            let node = StreamingInfoRepositoryTests.makeNode()
            let sut = StreamingInfoRepositoryTests.makeSUT(sdk: StreamingInfoRepositoryTests.makeSdk(localLink: StreamingInfoRepositoryTests.localURL))
            
            #expect(sut.fetchTrack(from: node) != nil)
        }
        
        @Test("item has expected name, url and node reference")
        func item_fields_areCorrect() {
            let node = StreamingInfoRepositoryTests.makeNode()
            let sut = StreamingInfoRepositoryTests.makeSUT(sdk: StreamingInfoRepositoryTests.makeSdk(localLink: StreamingInfoRepositoryTests.localURL))
            
            let item = sut.fetchTrack(from: node)
            
            #expect(item?.name == StreamingInfoRepositoryTests.defaultName)
            #expect(item?.url == StreamingInfoRepositoryTests.localURL)
            #expect(item?.node as AnyObject === node)
        }
    }
    
    @Suite("Path resolution")
    struct PathResolution {
        @Test(
            "returns correct path depending on link presence",
            arguments: [
                (link: StreamingInfoRepositoryTests.localURL, expected: StreamingInfoRepositoryTests.localURL),
                (link: nil, expected: nil)
            ]
        )
        func pathMatchesLinkPresence(args: (link: URL?, expected: URL?)) {
            let node = StreamingInfoRepositoryTests.makeNode()
            let sut = StreamingInfoRepositoryTests.makeSUT(
                sdk: StreamingInfoRepositoryTests.makeSdk(
                    nodes: [node],
                    localLink: args.link,
                    isLocalOnly: true
                )
            )
            #expect(sut.streamingURL(for: node) == args.expected)
        }
    }
    
    @Suite("Server status")
    struct ServerStatus {
        @Test(
            "returns correct running state",
            arguments: [
                (isRunning: false, expected: false),
                (isRunning: true, expected: true)
            ]
        )
        func returnsExpectedRunningState(args: (isRunning: Bool, expected: Bool)) {
            let sut = StreamingInfoRepositoryTests.makeSUT(sdk: StreamingInfoRepositoryTests.makeSdk(isRunning: args.isRunning))
            #expect(sut.isLocalHTTPServerRunning() == args.expected)
        }
    }
}
