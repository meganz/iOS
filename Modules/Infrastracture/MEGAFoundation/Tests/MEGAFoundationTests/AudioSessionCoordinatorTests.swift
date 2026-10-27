import MEGAFoundation
import Testing

@Suite("AudioSessionCoordinator")
struct AudioSessionCoordinatorTests {
    @Test func releasingTheOnlyOwner_letsTheSessionBeDeactivated() {
        let sut = AudioSessionCoordinator()
        sut.acquire("audio")

        #expect(sut.release("audio"))
    }

    /// The case behind this type: audio closing while a video plays in Picture in Picture
    @Test func releasingOneOwner_keepsTheSessionForTheOthers() {
        let sut = AudioSessionCoordinator()
        sut.acquire("audio")
        sut.acquire("video")

        #expect(sut.release("audio") == false)
        #expect(sut.release("video"))
    }

    @Test func acquiringTwiceUnderOneOwner_isReleasedOnce() {
        let sut = AudioSessionCoordinator()
        sut.acquire("audio")
        sut.acquire("audio")

        #expect(sut.release("audio"))
    }

    @Test func releasingAnOwnerThatHoldsNothing_doesNotAffectTheOthers() {
        let sut = AudioSessionCoordinator()
        sut.acquire("video")

        #expect(sut.release("audio") == false)
        #expect(sut.release("video"))
    }
}
