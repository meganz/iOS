import MEGADomain
import Testing
@preconcurrency @testable import Video

struct VideoRevampSyncModelTests {

    @Test func testSelectVideos_whenInvoked_shouldChangeToEditModeAndSelectVideosByDefault() {
        let sut = VideoRevampSyncModel()
        let node = NodeEntity()
        sut.selectVideos([node])
        #expect(sut.editMode == .active)
        #expect(sut.selectedVideos == [node])
    }
}
