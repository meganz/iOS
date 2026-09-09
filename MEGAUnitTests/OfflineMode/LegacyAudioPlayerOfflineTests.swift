@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@MainActor
@Suite("Legacy audio player offline mode")
struct LegacyAudioPlayerOfflineTests {

    // MARK: - Playback

    /// The probe is `getDownloadUrl`, a request the SDK retries until connectivity returns. Awaiting
    /// it offline held the player on its loading state forever, which is the reported symptom: the
    /// file does not open and nothing is shown.
    @Test("Offline, the takedown probe is never sent", .timeLimit(.minutes(1)))
    func offlineDoesNotProbeForTakedown() async throws {
        let node = audioNode(1)
        let (sut, playerHandler, nodeInfoUseCase, router) = makeSUT(
            node: node,
            isConnected: false,
            offlineTracksInParentFolder: [track(for: node)]
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { playerHandler.setCurrent_tracks.isNotEmpty }
        #expect(nodeInfoUseCase.isTakenDown_callTimes == 0)
        #expect(router.showTermsOfServiceViolationAlert_calledTimes == 0)
        #expect(router.dismiss_calledTimes == 0)
    }

    @Test("Offline, the node plays from its local copy", .timeLimit(.minutes(1)))
    func offlinePlaysTheLocalCopy() async throws {
        let node = audioNode(1)
        let (sut, playerHandler, _, _) = makeSUT(
            node: node,
            isConnected: false,
            offlineTracksInParentFolder: [track(for: node)]
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { playerHandler.setCurrent_tracks.isNotEmpty }
        #expect(playerHandler.setCurrent_tracks.map(\.url) == [localURL(1)])
    }

    @Test("Offline, the queue holds only the siblings with a local copy", .timeLimit(.minutes(1)))
    func offlineQueueDropsWhatCannotPlay() async throws {
        let nodes = [audioNode(1), audioNode(2), audioNode(3)]
        // Node 2 has no local copy, so it must not reach the queue: it could only be streamed, and
        // it would stall the moment it came up.
        let (sut, playerHandler, _, _) = makeSUT(
            node: nodes[0],
            isConnected: false,
            offlineTracksInParentFolder: [track(for: nodes[0]), track(for: nodes[2])]
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { playerHandler.setCurrent_tracks.isNotEmpty }
        #expect(playerHandler.setCurrent_tracks.map(\.url) == [localURL(1), localURL(3)])
    }

    /// Refusing to open such a file belongs to the tap site, which shows the message; by the time
    /// the player is up there is nothing left to play.
    @Test("Offline, a node with no local copy dismisses the player", .timeLimit(.minutes(1)))
    func offlineWithoutLocalCopyDismisses() async throws {
        let node = audioNode(1)
        let (sut, playerHandler, _, router) = makeSUT(
            node: node,
            isConnected: false,
            offlineTracksInParentFolder: []
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { router.dismiss_calledTimes == 1 }
        #expect(playerHandler.setCurrent_tracks.isEmpty)
    }

    /// The offline path is part of offline mode, so it must not reach a build where the feature is
    /// off: there the tap site does not show the no-connection message either, and dismissing the
    /// player would leave the user with nothing at all.
    @Test("With offline mode off, being offline changes nothing", .timeLimit(.minutes(1)))
    func offlineModeDisabledKeepsTheOnlinePath() async throws {
        let node = audioNode(1)
        let (sut, _, nodeInfoUseCase, _) = makeSUT(
            node: node,
            isConnected: false,
            isNewOfflineModeEnabled: false,
            audioTracksInParentFolder: [track(for: node)],
            offlineTracksInParentFolder: [track(for: node)]
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { nodeInfoUseCase.isTakenDown_callTimes > 0 }
        #expect(nodeInfoUseCase.offlineQueue_callTimes == 0)
    }

    @Test("Online, the takedown probe still runs", .timeLimit(.minutes(1)))
    func onlineStillProbesForTakedown() async throws {
        let node = audioNode(1)
        let (sut, _, nodeInfoUseCase, _) = makeSUT(
            node: node,
            isConnected: true,
            audioTracksInParentFolder: [track(for: node)]
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { nodeInfoUseCase.isTakenDown_callTimes > 0 }
    }

    // MARK: - Three-dot sheet

    @Test("The three-dot sheet's actions go through the offline guard")
    func threeDotSheetIsOfflineAware() {
        let router = AudioPlayerViewRouter(
            configEntity: AudioPlayerConfigEntity(node: audioNode(1), isFolderLink: false, fileLink: nil),
            presenter: UIViewController(),
            tracker: MockTracker(),
            offlineActionGuard: MockOfflineActionGuard(allowsAction: false)
        )

        let sheet = router.makeNodeActionViewController(for: audioNode(1), isFileLink: false, sender: UIView())

        #expect(sheet.delegate is OfflineAwareNodeActionDelegate)
    }

    // MARK: - Mini player

    /// Tapping a second file while the mini player is up never opens the full-screen player: it
    /// refreshes the mini player instead, so the same probe runs here. Failing it used to take the
    /// delegate registration that sits below it down as well.
    @Test("Offline, the mini player skips the takedown probe and still registers the delegate", .timeLimit(.minutes(1)))
    func offlineMiniPlayerDoesNotProbeForTakedown() async throws {
        let node = audioNode(1)
        let (sut, playerHandler, nodeInfoUseCase, audioPlayerUseCase, _, router) = makeMiniPlayerSUT(
            node: node,
            isConnected: false,
            offlineTracksInParentFolder: [track(for: node)]
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { playerHandler.addPlayer_tracks.isNotEmpty }
        try await wait { audioPlayerUseCase.registerMEGADelegate_callTimes == 1 }
        #expect(nodeInfoUseCase.isTakenDown_callTimes == 0)
        #expect(router.showTermsOfServiceViolationAlert_calledTimes == 0)
        #expect(router.dismiss_calledTimes == 0)
    }

    @Test("Offline, the mini player plays the node from its local copy", .timeLimit(.minutes(1)))
    func offlineMiniPlayerPlaysTheLocalCopy() async throws {
        let node = audioNode(1)
        let (sut, playerHandler, _, _, streamingInfoUseCase, _) = makeMiniPlayerSUT(
            node: node,
            isConnected: false,
            offlineTracksInParentFolder: [track(for: node)]
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { playerHandler.addPlayer_tracks.isNotEmpty }
        #expect(playerHandler.addPlayer_tracks.map(\.url) == [localURL(1)])
        // Nothing can be streamed with no connection, so the local server has no reason to come up.
        #expect(streamingInfoUseCase.startServer_calledTimes == 0)
    }

    @Test("Offline, the mini player queue holds only the siblings with a local copy", .timeLimit(.minutes(1)))
    func offlineMiniPlayerQueueDropsWhatCannotPlay() async throws {
        let nodes = [audioNode(1), audioNode(2), audioNode(3)]
        let (sut, playerHandler, _, _, _, _) = makeMiniPlayerSUT(
            node: nodes[0],
            isConnected: false,
            offlineTracksInParentFolder: [track(for: nodes[0]), track(for: nodes[2])]
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { playerHandler.addPlayer_tracks.isNotEmpty }
        #expect(playerHandler.addPlayer_tracks.map(\.url) == [localURL(1), localURL(3)])
    }

    @Test("Offline, a node with no local copy dismisses the mini player", .timeLimit(.minutes(1)))
    func offlineMiniPlayerWithoutLocalCopyDismisses() async throws {
        let node = audioNode(1)
        let (sut, playerHandler, _, _, _, router) = makeMiniPlayerSUT(
            node: node,
            isConnected: false,
            offlineTracksInParentFolder: []
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { router.dismiss_calledTimes == 1 }
        #expect(playerHandler.addPlayer_tracks.isEmpty)
    }

    @Test("Online, the mini player still probes for takedown", .timeLimit(.minutes(1)))
    func onlineMiniPlayerStillProbesForTakedown() async throws {
        let node = audioNode(1)
        let (sut, _, nodeInfoUseCase, _, _, _) = makeMiniPlayerSUT(
            node: node,
            isConnected: true,
            audioTracksInParentFolder: [track(for: node)]
        )

        sut.dispatch(.onViewDidLoad)

        try await wait { nodeInfoUseCase.isTakenDown_callTimes > 0 }
        #expect(nodeInfoUseCase.offlineQueue_callTimes == 0)
    }

    // MARK: - Helpers

    private func audioNode(_ handle: MEGAHandle) -> MockNode {
        MockNode(handle: handle, name: "song\(handle).mp3", parentHandle: parentHandle)
    }

    private var parentHandle: MEGAHandle { 100 }

    private func localURL(_ handle: MEGAHandle) -> URL {
        URL(fileURLWithPath: "/offline/song\(handle).mp3")
    }

    private func track(for node: MockNode) -> TrackEntity {
        TrackEntity(url: localURL(node.handle), node: node)
    }

    /// `Task.sleep` is what makes the enclosing `.timeLimit` able to end this: it throws when the
    /// task is cancelled, so "the work never happened" fails the test instead of hanging it.
    private func wait(until condition: () -> Bool) async throws {
        while !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    private func makeSUT(
        node: MockNode,
        isConnected: Bool,
        isNewOfflineModeEnabled: Bool = true,
        audioTracksInParentFolder: [TrackEntity] = [],
        offlineTracksInParentFolder: [TrackEntity] = []
    ) -> (
        sut: AudioPlayerViewModel,
        playerHandler: MockAudioPlayerHandler,
        nodeInfoUseCase: MockNodeInfoUseCase,
        router: MockAudioPlayerViewRouter
    ) {
        let playerHandler = MockAudioPlayerHandler()
        let router = MockAudioPlayerViewRouter()
        let nodeInfoUseCase = makeNodeInfoUseCase(
            audioTracksInParentFolder: audioTracksInParentFolder,
            offlineTracksInParentFolder: offlineTracksInParentFolder
        )
        let sut = AudioPlayerViewModel(
            configEntity: AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil),
            playerHandler: playerHandler,
            router: router,
            nodeInfoUseCase: nodeInfoUseCase,
            streamingInfoUseCase: MockStreamingInfoUseCase(),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(),
            audioPlayerUseCase: MockAudioPlayerUseCase(),
            accountUseCase: MockAccountUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: isConnected),
            isNewOfflineModeEnabled: isNewOfflineModeEnabled,
            tracker: MockTracker()
        )
        return (sut, playerHandler, nodeInfoUseCase, router)
    }

    private func makeMiniPlayerSUT(
        node: MockNode,
        isConnected: Bool,
        isNewOfflineModeEnabled: Bool = true,
        audioTracksInParentFolder: [TrackEntity] = [],
        offlineTracksInParentFolder: [TrackEntity] = []
    ) -> (
        sut: MiniPlayerViewModel,
        playerHandler: MockAudioPlayerHandler,
        nodeInfoUseCase: MockNodeInfoUseCase,
        audioPlayerUseCase: MockAudioPlayerUseCase,
        streamingInfoUseCase: MockStreamingInfoUseCase,
        router: MockMiniPlayerViewRouter
    ) {
        let playerHandler = MockAudioPlayerHandler()
        let router = MockMiniPlayerViewRouter()
        let nodeInfoUseCase = makeNodeInfoUseCase(
            audioTracksInParentFolder: audioTracksInParentFolder,
            offlineTracksInParentFolder: offlineTracksInParentFolder
        )
        let audioPlayerUseCase = MockAudioPlayerUseCase()
        let streamingInfoUseCase = MockStreamingInfoUseCase()
        let sut = MiniPlayerViewModel(
            configEntity: AudioPlayerConfigEntity(node: node, isFolderLink: false, fileLink: nil, shouldResetPlayer: true),
            playerHandler: playerHandler,
            router: router,
            nodeInfoUseCase: nodeInfoUseCase,
            streamingInfoUseCase: streamingInfoUseCase,
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: MockOfflineInfoRepository()),
            playbackContinuationUseCase: MockPlaybackContinuationUseCase(),
            audioPlayerUseCase: audioPlayerUseCase,
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: isConnected),
            isNewOfflineModeEnabled: isNewOfflineModeEnabled
        )
        return (sut, playerHandler, nodeInfoUseCase, audioPlayerUseCase, streamingInfoUseCase, router)
    }

    private func makeNodeInfoUseCase(
        audioTracksInParentFolder: [TrackEntity],
        offlineTracksInParentFolder: [TrackEntity]
    ) -> MockNodeInfoUseCase {
        MockNodeInfoUseCase(
            audioTracksInFolder: [parentHandle: audioTracksInParentFolder],
            offlineAudioTracksInFolder: [parentHandle: offlineTracksInParentFolder],
            offlineTrackForHandle: offlineTracksInParentFolder.reduce(into: [:]) { result, track in
                guard let handle = track.node?.handle else { return }
                result[handle] = track
            }
        )
    }
}
