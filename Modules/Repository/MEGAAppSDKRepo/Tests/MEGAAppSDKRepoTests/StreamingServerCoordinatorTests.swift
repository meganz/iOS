import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import Testing

@Suite("StreamingServerCoordinator")
struct StreamingServerCoordinatorTests {
    @Test func firstOwner_startsTheServer() {
        let sdk = MockSdk()
        let sut = StreamingServerCoordinator()

        sut.acquire("audio", on: sdk)

        #expect(sdk.httpServerStart_calledTimes == 1)
        #expect(sdk.httpServerStart_lastArgs?.localOnly == false)
        #expect(sdk.httpServerStart_lastArgs?.port == 4443)
    }

    /// Starting a running server revokes every link it has handed out
    @Test func runningServer_isNeverStartedAgain() {
        let sdk = MockSdk(isRunning: true)
        let sut = StreamingServerCoordinator()

        sut.acquire("audio", on: sdk)
        sut.acquire("video", on: sdk)
        sut.acquire("audio", on: sdk)

        #expect(sdk.httpServerStart_calledTimes == 0)
    }

    /// The case behind this type: a video closing while audio still streams
    @Test func releasingOneOwner_keepsTheServerForTheOthers() {
        let sdk = MockSdk()
        let sut = StreamingServerCoordinator()
        sut.acquire("audio", on: sdk)
        sut.acquire("video", on: sdk)

        sut.release("video")

        #expect(sdk.httpServerStop_calledTimes == 0)
        #expect(sdk.httpServerIsRunning() == 1)
    }

    @Test func releasingTheLastOwner_stopsTheServer() {
        let sdk = MockSdk()
        let sut = StreamingServerCoordinator()
        sut.acquire("audio", on: sdk)
        sut.acquire("video", on: sdk)

        sut.release("video")
        sut.release("audio")

        #expect(sdk.httpServerStop_calledTimes == 1)
    }

    @Test func releasingTwice_stopsOnlyOnce() {
        let sdk = MockSdk()
        let sut = StreamingServerCoordinator()
        sut.acquire("audio", on: sdk)

        sut.release("audio")
        sut.release("audio")

        #expect(sdk.httpServerStop_calledTimes == 1)
    }

    /// A server started by a player outside the coordinator is not this owner's to stop
    @Test func releasingAnOwnerThatHoldsNothing_leavesTheServerAlone() {
        let sdk = MockSdk(isRunning: true)
        let sut = StreamingServerCoordinator()

        sut.release("audio")

        #expect(sdk.httpServerStop_calledTimes == 0)
    }

    /// Stopped behind the coordinator's back — by a player outside it — the server comes back for the next hold
    @Test func acquire_restartsAServerStoppedFromOutside() {
        let sdk = MockSdk()
        let sut = StreamingServerCoordinator()
        sut.acquire("audio", on: sdk)

        sdk.httpServerStop()
        sut.acquire("audio", on: sdk)

        #expect(sdk.httpServerStart_calledTimes == 2)
    }

    @Test func eachSDK_isHeldSeparately() {
        let accountSDK = MockSdk()
        let folderLinkSDK = MockSdk()
        let sut = StreamingServerCoordinator()
        sut.acquire("audio", on: accountSDK)
        sut.acquire("video", on: folderLinkSDK)

        sut.release("video")

        #expect(folderLinkSDK.httpServerStop_calledTimes == 1)
        #expect(accountSDK.httpServerStop_calledTimes == 0)
    }
}
