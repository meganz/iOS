@testable import MEGAAudioPlayer
import Testing

@MainActor
struct AudioPlayerViewModelTransportControlsTests {
    @Test func singleTrack_isSingleTrackTrue_andOnLastTrack() {
        let vm = AudioPlayerViewModel()
        vm.setQueueForPreview(titles: ["Only Song"], currentIndex: 0)

        #expect(vm.isSingleTrack)
        #expect(vm.isOnLastTrack)
    }

    @Test func multiTrack_currentInMiddle_isNotSingleNorLast() {
        let vm = AudioPlayerViewModel()
        vm.setQueueForPreview(titles: ["A", "B", "C"], currentIndex: 1)

        #expect(!vm.isSingleTrack)
        #expect(!vm.isOnLastTrack)
    }

    @Test func multiTrack_currentIsLast_isOnLastTrackButNotSingle() {
        let vm = AudioPlayerViewModel()
        vm.setQueueForPreview(titles: ["A", "B", "C"], currentIndex: 2)

        #expect(!vm.isSingleTrack)
        #expect(vm.isOnLastTrack)
    }

    @Test func emptyQueue_isNeitherSingleNorLast() {
        let vm = AudioPlayerViewModel()

        #expect(!vm.isSingleTrack)
        #expect(!vm.isOnLastTrack)
    }
}
