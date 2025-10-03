@testable import MEGA
import MEGAAppSDKRepoMock
import MEGASdk
import Testing

@Suite("StreamingInfoRepository")
struct StreamingInfoRepositoryTests {
    static let defaultName = "any-name"
    static let localURL = URL(string: "http://127.0.0.1:4443/file")!
    static let updatedURL = URL(string: "http://10.0.0.2:4443/file")!
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
    
    @Suite("HTTP Server Lifecycle")
    struct HttpServerLifecycleSuite {
        @Test("startServer() starts the HTTP server exactly once")
        func startServer_startsHttpServerOnce() {
            let sdk = makeSdk()
            let sut = makeSUT(sdk: sdk)
            sut.serverStart()
            #expect(sdk.httpServerStart_calledTimes == 1)
        }
        
        @Test("startServer() sets localOnly to false")
        func startServer_setsLocalOnlyToFalse() {
            let sdk = makeSdk()
            let sut = makeSUT(sdk: sdk)
            sut.serverStart()
            #expect(sdk.httpServerStart_lastArgs?.localOnly == false)
        }
        
        @Test("startServer() uses the expected default port")
        func startServer_usesExpectedDefaultPort() {
            let sdk = makeSdk()
            let sut = makeSUT(sdk: sdk)
            sut.serverStart()
            #expect(sdk.httpServerStart_lastArgs?.port == defaultPort)
        }
        
        @Test("stopServer() stops the HTTP server exactly once")
        func stopServer_stopsHttpServerOnce() {
            let sdk = makeSdk()
            let sut = makeSUT(sdk: sdk)
            sut.serverStop()
            #expect(sdk.httpServerStop_calledTimes == 1)
        }
    }
    
    @Suite("Track Mapping (fetchTrack)")
    struct TrackMappingSuite {
        @Test(
            "fetchTrack(from:) returns nil when node is unauthorized or link missing",
            arguments: [
                (node: MEGANode(), sdk: makeSdk(localLink: localURL)),
                (node: makeNode(), sdk: makeSdk(localLink: nil))
            ]
        )
        func fetchTrack_returnsNilForInvalidInputs(_ args: (node: MEGANode, sdk: MockSdk)) {
            let sut = makeSUT(sdk: args.sdk)
            #expect(sut.fetchTrack(from: args.node) == nil)
        }
        
        @Test("fetchTrack(from:) returns an item when node is valid and link exists")
        func fetchTrack_returnsItemForValidNodeAndLink() {
            let node = makeNode()
            let sut = makeSUT(
                sdk: makeSdk(localLink: localURL)
            )
            #expect(sut.fetchTrack(from: node) != nil)
        }
        
        @Test(arguments: [true, false])
        func fetchTrack_setsHasThumbnailFromNode(_ hasThumb: Bool) {
            let node = makeNode(hasThumb ? 1 : 2, hasThumb: hasThumb)
            let sut = makeSUT(
                sdk: makeSdk(localLink: localURL)
            )
            let item = sut.fetchTrack(from: node)
            #expect(item?.nodeHasThumbnail == hasThumb)
        }
        
        @Test("fetchTrack(from:) populates name, url, and node reference")
        func fetchTrack_populatesFieldsCorrectly() {
            let node = makeNode()
            let sut = makeSUT(
                sdk: makeSdk(localLink: localURL)
            )
            let item = sut.fetchTrack(from: node)
            #expect(item?.name == defaultName)
            #expect(item?.url == localURL)
            #expect(item?.node as AnyObject === node)
        }
    }
    
    @Suite("Streaming URL Resolution")
    struct StreamingURLResolutionSuite {
        @Test(
            "streamingURL(for:) returns expected value based on link presence when localOnly is true",
            arguments: [
                (link: localURL, expected: localURL),
                (link: nil, expected: nil)
            ]
        )
        func streamingURL_returnsLinkWhenLocalOnly(_ args: (link: URL?, expected: URL?)) {
            let node = makeNode()
            let sut = makeSUT(
                sdk: makeSdk(
                    nodes: [node],
                    localLink: args.link,
                    isLocalOnly: true
                )
            )
            #expect(sut.streamingURL(for: node) == args.expected)
        }
        
        @Test("streamingURL(for:) returns address-updated URL when localOnly is false and link exists")
        func streamingURL_returnsUpdatedAddressWhenNotLocalOnly() {
            let node = makeNode()
            let sut = makeSUT(
                sdk: makeSdk(
                    nodes: [node],
                    localLink: localURL,
                    isLocalOnly: false,
                    updatedAddressURL: updatedURL
                )
            )
            #expect(sut.streamingURL(for: node) == updatedURL)
        }
        
        @Test("streamingURL(for:) returns nil when localOnly is false, link exists, but updated address is unavailable")
        func streamingURL_returnsNilWhenUpdatedAddressMissing() {
            let node = makeNode()
            let sut = makeSUT(
                sdk: makeSdk(
                    nodes: [node],
                    localLink: localURL,
                    isLocalOnly: false,
                    updatedAddressURL: nil
                )
            )
            #expect(sut.streamingURL(for: node) == nil)
        }
    }
    
    @Suite("HTTP Server Running State")
    struct HttpServerRunningStateSuite {
        @Test(
            "isLocalHTTPServerRunning() reflects SDK running state",
            arguments: [
                (isRunning: false, expected: false),
                (isRunning: true, expected: true)
            ]
        )
        func isLocalHTTPServerRunning_reflectsSdkState(_ args: (isRunning: Bool, expected: Bool)) {
            let sut = makeSUT(
                sdk: makeSdk(isRunning: args.isRunning)
            )
            #expect(sut.isLocalHTTPServerRunning() == args.expected)
        }
    }
}
