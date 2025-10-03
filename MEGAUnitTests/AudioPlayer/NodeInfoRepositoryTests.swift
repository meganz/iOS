@testable import MEGA
import MEGAAppSDKRepoMock
import Testing

struct NodeInfoRepositoryTests {
    static let defaultNode = MockNode(handle: 1)
    
    static func makeSUT(
        sdk: MockSdk = MockSdk(),
        folderSdk: MockFolderSdk = MockFolderSdk(isLoggedIn: true),
        megaStore: MEGAStore = MEGAStore(),
        offlineInfoRepository: MockOfflineInfoRepository = MockOfflineInfoRepository(result: .success),
        streamingInfoRepository: MockStreamingInfoRepository = MockStreamingInfoRepository(result: .success),
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> (
        sut: NodeInfoRepository,
        sdk: MockSdk,
        folderSdk: MockFolderSdk,
        offline: MockOfflineInfoRepository,
        streaming: MockStreamingInfoRepository
    ) {
        let sut = NodeInfoRepository(
            sdk: sdk,
            folderSDK: folderSdk,
            megaStore: megaStore,
            offlineFileInfoRepository: offlineInfoRepository,
            streamingInfoRepository: streamingInfoRepository
        )
        return (sut, sdk, folderSdk, offlineInfoRepository, streamingInfoRepository)
    }
    
    static func anyNode(
        handle: MEGAHandle = 1,
        name: String = "",
        parentHandle: MEGAHandle = 100,
        isTakenDown: Bool = false
    ) -> MockNode {
        MockNode(
            handle: handle,
            name: name,
            parentHandle: parentHandle,
            isTakenDown: isTakenDown
        )
    }
    
    static func authorizeAll(_ nodes: [MockNode], in sdk: MockFolderSdk) {
        nodes.forEach(sdk.mockAuthorizeNode(with:))
    }
    
    static func makeChildren(parent: MEGAHandle, names: [String]) -> [MockNode] {
        names.enumerated().map { i, name in
            anyNode(handle: MEGAHandle(2 + i), name: name, parentHandle: parent)
        }
    }
    
    @Suite("Folder-link session")
    struct FolderLinkLogoutSuite {
        @Test("logout completes in folder SDK")
        func folderLinkLogoutLogsOut() {
            let (sut, _, folderSdk, _, _) = makeSUT()
            sut.folderLinkLogout()
            #expect(folderSdk.folderLinkLogoutCallCount == 1)
        }
    }
    
    @Suite("Node lookup")
    struct NodeLookupSuite {
        @Test("node(for:) uses SDK lookup")
        func nodeLookupCallsSdk() {
            let (sut, sdk, _, _, _) = makeSUT(sdk: MockSdk())
            _ = sut.node(for: .invalid)
            #expect(sdk.nodeForHandleCallCount == 1)
        }
    }
    
    @Suite("Playback URL")
    struct PlaybackURLSuite {
        @Test("returns nil when handle not found")
        func returnsNilWhenNodeMissing() {
            let (sut, _, _, _, _) = makeSUT(sdk: MockSdk(nodes: []))
            #expect(sut.playbackURL(for: .invalid) == nil)
        }
        
        @Test("checks offline first when available")
        func checksOfflineFirst() {
            let (sut, _, _, offline, _) = makeSUT(
                sdk: MockSdk(nodes: [defaultNode]),
                offlineInfoRepository: MockOfflineInfoRepository(result: .success, isOffline: true)
            )
            _ = sut.playbackURL(for: defaultNode.handle)
            #expect(offline.localPathfromNodeCallCount == 1)
        }
        
        @Test("falls back to streaming when offline path is nil")
        func fallsBackToStreaming() {
            let (sut, _, _, _, streaming) = makeSUT(
                sdk: MockSdk(nodes: [defaultNode]),
                offlineInfoRepository: MockOfflineInfoRepository(result: .failure(.generic)),
                streamingInfoRepository: MockStreamingInfoRepository(result: .success)
            )
            _ = sut.playbackURL(for: defaultNode.handle)
            #expect(streaming.pathFromNodeCallCount == 1)
        }
    }
    
    @Suite("Node → AudioPlayerItem mapping – sequence")
    struct MakeItemsSequenceSuite {
        @Test(arguments: [
            [String](),
            ["n0"],
            ["n0", "n1", "n2"]
        ])
        func mapsNodesToItemsPreservingNames(_ names: [String]) {
            let nodes: [MockNode] = names.enumerated().map { i, name in
                anyNode(handle: MEGAHandle(10 + i), name: name, parentHandle: 1)
            }
            let (sut, _, _, _, _) = makeSUT(
                sdk: MockSdk(nodes: nodes),
                streamingInfoRepository: MockStreamingInfoRepository(result: .success)
            )
            let items = sut.makeAudioPlayerItems(from: nodes)
            if names.isEmpty {
                #expect(items == nil || items?.isEmpty == true)
            } else {
                let unwrapped = try! #require(items)
                #expect(unwrapped.map(\.name) == names)
            }
        }
    }
    
    @Suite("Fetch audio tracks (account folders) – sequence")
    struct FetchAccountSequenceSuite {
        @Test(arguments: [
            (MEGAHandle(1), ["c0.mp3"]),
            (MEGAHandle(1), ["c0.mp3", "c1.mp3"]),
            (MEGAHandle(42), ["intro.mp3", "song.mp3", "outro.mp3"])
        ])
        func itemsMatchChildrenSequence(_ parent: MEGAHandle, _ children: [String]) throws {
            let parentNode  = anyNode(handle: parent, name: "parent.mp3", parentHandle: 100)
            let childNodes  = makeChildren(parent: parent, names: children)
            let (sut, _, _, _, _) = makeSUT(sdk: MockSdk(nodes: [parentNode] + childNodes))
            let items = try #require(sut.fetchAudioTracks(from: parentNode.handle))
            #expect(items.count == children.count)
            #expect(items.map(\.name) == children)
            #expect(Set(items.compactMap { $0.node?.parentHandle }) == [parent])
        }
    }
    
    @Suite("Fetch audio tracks (folder-link) – sequence")
    struct FetchLinkSequenceSuite {
        @Test(arguments: [
            (MEGAHandle(1), ["x.mp3"]),
            (MEGAHandle(9), ["x.mp3", "y.mp3"]),
            (MEGAHandle(9), ["x.mp3", "y.mp3", "z.mp3"])
        ])
        func itemsMatchChildrenSequence_link(_ parent: MEGAHandle, _ children: [String]) throws {
            let parentNode = anyNode(handle: parent, name: "p.mp3", parentHandle: 100)
            let childNodes = makeChildren(parent: parent, names: children)
            let nodes = [parentNode] + childNodes
            let folderSdk = MockFolderSdk(isLoggedIn: true, nodes: nodes)
            let (sut, _, _, _, _) = makeSUT(
                sdk: MockSdk(nodes: nodes),
                folderSdk: folderSdk,
                streamingInfoRepository: MockStreamingInfoRepository(result: .success)
            )
            authorizeAll(nodes, in: folderSdk)
            let items = try #require(sut.fetchFolderLinkAudioTracks(from: parentNode.handle))
            #expect(items.count == children.count)
            #expect(items.map(\.name) == children)
            #expect(Set(items.compactMap { $0.node?.parentHandle }) == [parent])
        }
    }
    
    @Suite("Playback URL – offline vs streaming")
    struct PlaybackTruthTableSuite {
        @Test(arguments: [
            (true, false),
            (false, true)
        ])
        func resolvesURL(_ isOffline: Bool, _ expectStreamingFallback: Bool) {
            let offlineRepo = isOffline
            ? MockOfflineInfoRepository(result: .success, isOffline: true)
            : MockOfflineInfoRepository(result: .failure(.generic), isOffline: false)
            let (sut, _, _, offline, streaming) = makeSUT(
                sdk: MockSdk(nodes: [defaultNode]),
                offlineInfoRepository: offlineRepo,
                streamingInfoRepository: MockStreamingInfoRepository(result: .success)
            )
            _ = sut.playbackURL(for: defaultNode.handle)
            if expectStreamingFallback {
                #expect(streaming.pathFromNodeCallCount == 1)
            } else {
                #expect(offline.localPathfromNodeCallCount == 1)
                #expect(streaming.pathFromNodeCallCount == 0)
            }
        }
    }
    
    @Suite("Takedown checks")
    struct TakedownSuite {
        @Test("node not taken down when API returns URL")
        func nodeNotTakenDownWhenOK() async throws {
            let sdk = MockSdk(nodes: [defaultNode], megaSetError: .apiOk)
            let (sut, _, _, _, _) = makeSUT(sdk: sdk)
            let result = try await sut.isNodeTakenDown(node: defaultNode)
            #expect(result == false)
        }
        
        @Test("node taken down when API returns .apiEBlocked")
        func nodeTakenDownWhenBlocked() async throws {
            let sdk = MockSdk(nodes: [defaultNode], megaSetError: .apiEBlocked)
            let (sut, _, _, _, _) = makeSUT(sdk: sdk)
            let result = try await sut.isNodeTakenDown(node: defaultNode)
            #expect(result == true)
        }
        
        @Test("node throws when API returns unexpected error")
        func nodeThrowsWhenError() async {
            let sdk = MockSdk(nodes: [defaultNode], megaSetError: .apiETooMany)
            let (sut, _, _, _, _) = makeSUT(sdk: sdk)
            await #expect(throws: (any Error).self) {
                _ = try await sut.isNodeTakenDown(node: defaultNode)
            }
        }
        
        @Test("folder-link taken down when API returns .apiEBlocked")
        func folderLinkTakenDownWhenBlocked() async throws {
            let folderSdk = MockFolderSdk(isLoggedIn: true, nodes: [defaultNode], errorType: .apiEBlocked)
            let (sut, _, _, _, _) = makeSUT(
                sdk: MockSdk(nodes: [defaultNode]),
                folderSdk: folderSdk
            )
            let result = try await sut.isFolderLinkNodeTakenDown(node: defaultNode)
            #expect(result == true)
        }
    }
}
