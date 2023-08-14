protocol AudioPlayerPlaylistShiftStrategyTestSpecs {
    func testShift_whenHasNoTracks_returnsEmptyTracks()
    func testShift_whenHasSingleTrack_returnsStartItem()
    func testShift_whenHasMoreThanOneTracks_returnsCorrectOrderTracks()
}
