@testable import MEGAAudioPlayer
import Testing

@MainActor
struct AudioPlayerViewModelTransportControlsTests {
    @Test func singleTrack_isSingleTrackTrue_andOnLastTwoTracks() {
        let vm = AudioPlayerViewModel()
        vm.setQueueForPreview(titles: ["Only Song"], currentIndex: 0)

        #expect(vm.isSingleTrack)
        #expect(vm.isOnLastTwoTracks)
    }

    @Test func multiTrack_currentInMiddle_isNotSingleNorInLastTwo() {
        let vm = AudioPlayerViewModel()
        vm.setQueueForPreview(titles: ["A", "B", "C", "D"], currentIndex: 1)

        #expect(!vm.isSingleTrack)
        #expect(!vm.isOnLastTwoTracks)
    }

    /// The track before the last leaves a single upcoming track, which shuffles to itself —
    /// so it counts as "last two" even though it is not the last track.
    @Test func multiTrack_currentIsSecondToLast_isOnLastTwoTracks() {
        let vm = AudioPlayerViewModel()
        vm.setQueueForPreview(titles: ["A", "B", "C"], currentIndex: 1)

        #expect(!vm.isSingleTrack)
        #expect(vm.isOnLastTwoTracks)
    }

    @Test func multiTrack_currentIsLast_isOnLastTwoTracksButNotSingle() {
        let vm = AudioPlayerViewModel()
        vm.setQueueForPreview(titles: ["A", "B", "C"], currentIndex: 2)

        #expect(!vm.isSingleTrack)
        #expect(vm.isOnLastTwoTracks)
    }

    /// An empty queue has no current track, so it is neither single nor in the last two.
    @Test func emptyQueue_isNeitherSingleNorInLastTwo() {
        let vm = AudioPlayerViewModel()
        vm.setQueueForPreview(titles: [], currentIndex: 0)

        #expect(!vm.isSingleTrack)
        #expect(!vm.isOnLastTwoTracks)
    }

    /// A view model that has never been given a queue keeps the declared defaults; the real
    /// values arrive with the first `currentQueuePublisher` emission once a service is bound.
    @Test func viewModelWithoutQueue_keepsDefaults() {
        let vm = AudioPlayerViewModel()

        #expect(!vm.isSingleTrack)
        #expect(!vm.isOnLastTwoTracks)
    }
}
