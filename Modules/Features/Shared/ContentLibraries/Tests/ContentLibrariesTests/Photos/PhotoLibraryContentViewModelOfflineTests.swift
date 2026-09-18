import Combine
@testable import ContentLibraries
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGAL10n
import Testing

/// Every photo the library opens -- timeline, album, media discovery, album link -- goes through
/// `openPhoto`, so these cover the tap gate for all of them (IOS-12409).
///
/// The gate checks asynchronously, so each test waits on what the gate actually produces -- the
/// published snack bar, the `open` callback, or the guard being consulted -- never on elapsed time.
/// The time limit is there so a regression that stops producing it fails instead of hanging.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PhotoLibraryContentViewModelOfflineTests {
    private static let photo = NodeEntity(name: "holiday.jpg", handle: 1, isFile: true)
    private static let otherPhoto = NodeEntity(name: "sunset.jpg", handle: 2, isFile: true)

    @Test("A host that has not adopted offline mode opens without deferring the tap")
    func openPhotoWithoutGuard() {
        let sut = makeSUT(offlineFileOpenGuard: nil)
        var openCount = 0

        sut.openPhoto(Self.photo) { openCount += 1 }

        #expect(openCount == 1)
        #expect(sut.offlineSnackBar == nil)
    }

    @Test("While the guard is inactive the tap opens synchronously, nothing is checked")
    func openPhotoWithInactiveGuard() {
        let sut = makeSUT(offlineFileOpenGuard: MockOfflineFileOpenGuard(isActive: false, shouldBlock: true))
        var openCount = 0

        sut.openPhoto(Self.photo) { openCount += 1 }

        #expect(openCount == 1)
        #expect(sut.offlineSnackBar == nil)
    }

    @Test("A file with no local copy shows the snack bar instead of opening the browser")
    func openPhotoBlockedOffline() async {
        let sut = makeSUT(offlineFileOpenGuard: MockOfflineFileOpenGuard(isActive: true, shouldBlock: true))
        var openCount = 0

        sut.openPhoto(Self.photo) { openCount += 1 }

        #expect(await sut.nextSnackBarMessage() == Strings.Localizable.CloudDrive.Offline.fileNotAvailableOffline)
        #expect(openCount == 0)
    }

    @Test("A file with a local copy opens, and no snack bar is shown")
    func openPhotoAllowedOffline() async {
        let sut = makeSUT(offlineFileOpenGuard: MockOfflineFileOpenGuard(isActive: true, shouldBlock: false))

        // Resuming is the proof it opened: nothing else calls this closure
        await withCheckedContinuation { continuation in
            sut.openPhoto(Self.photo) { continuation.resume() }
        }

        #expect(sut.offlineSnackBar == nil)
    }

    @Test("A repeat tap while the check is running is dropped, a tap on another photo is not")
    func repeatTapWhileCheckingIsDropped() async {
        let guardSpy = SpyOfflineFileOpenGuard()
        let sut = makeSUT(offlineFileOpenGuard: guardSpy)
        var checks = guardSpy.checkedHandles.makeAsyncIterator()

        sut.openPhoto(Self.photo) { }
        sut.openPhoto(Self.photo) { }
        sut.openPhoto(Self.otherPhoto) { }

        #expect(await checks.next() == Self.photo.handle)
        // The repeat tap being dropped is what leaves the other photo as the second check
        #expect(await checks.next() == Self.otherPhoto.handle)
    }

    @Test("A photo tapped again once its check has finished is checked again")
    func tappingTheSamePhotoAgainAfterTheCheckFinished() async {
        let guardSpy = SpyOfflineFileOpenGuard()
        let sut = makeSUT(offlineFileOpenGuard: guardSpy)
        var checks = guardSpy.checkedHandles.makeAsyncIterator()

        sut.openPhoto(Self.photo) { }
        // Nothing suspends between the spy answering and the handle being released, so the test
        // resuming here means that check's task has finished its bookkeeping
        #expect(await checks.next() == Self.photo.handle)

        sut.openPhoto(Self.photo) { }

        #expect(await checks.next() == Self.photo.handle)
    }

    private func makeSUT(
        offlineFileOpenGuard: (any OfflineFileOpenGuarding)?
    ) -> PhotoLibraryContentViewModel {
        .init(
            library: PhotoLibrary(),
            tracker: MockTracker(),
            offlineFileOpenGuard: offlineFileOpenGuard
        )
    }
}

private extension PhotoLibraryContentViewModel {
    /// The next snack bar the gate publishes. Reading the message rather than the snack bar keeps
    /// what crosses the isolation boundary `Sendable`.
    func nextSnackBarMessage() async -> String? {
        for await message in $offlineSnackBar.compactMap({ @Sendable in $0?.message }).values {
            return message
        }
        return nil
    }
}

/// Reports each check as it is made, so a test can wait for the gate's asynchronous work to reach a
/// known point instead of guessing how long it takes.
private final class SpyOfflineFileOpenGuard: OfflineFileOpenGuarding, Sendable {
    let isActive = true
    let checkedHandles: AsyncStream<HandleEntity>
    private let continuation: AsyncStream<HandleEntity>.Continuation

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: HandleEntity.self)
        self.checkedHandles = stream
        self.continuation = continuation
    }

    func shouldBlockOpening(_ node: NodeEntity) async -> Bool {
        continuation.yield(node.handle)
        return true
    }
}
