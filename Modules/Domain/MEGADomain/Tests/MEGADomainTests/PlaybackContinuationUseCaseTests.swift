import MEGADomain
import MEGADomainMock
import XCTest

final class PlaybackContinuationUseCaseTests: XCTestCase {
    
    private var mockPreviousSessionRepo: MockPreviousPlaybackSessionRepository!
    
    func testStatus_shouldStartFromBeginning_whenPreviousPlaybackLessThanMinimum() {
        assertStatus(shouldBe: .startFromBeginning, whenLastPlaybackTime: nil)
        assertStatus(shouldBe: .startFromBeginning, whenLastPlaybackTime: lessThanMinimumTime)
    }
    
    func testStatus_shouldDisplayDialog_whenPreviousPlaybackMoreThanMinimum_andHasNoPreference() {
        let expectedTime = moreThanMinimumTime
        assertStatus(shouldBe: .displayDialog(playbackTime: expectedTime), whenLastPlaybackTime: expectedTime)
        assertStatus(shouldBe: .displayDialog(playbackTime: minimumTime), whenLastPlaybackTime: minimumTime)
    }
    
    func testStatus_shouldStartFromBeginning_whenPreviousPlaybackMoreThanMinimum_andPreferRestart() {
        assertStatus(
            shouldBe: .startFromBeginning,
            whenLastPlaybackTime: minimumTime,
            and: { sut in sut.setPreference(to: .restartFromBeginning) }
        )
        
        assertStatus(
            shouldBe: .startFromBeginning,
            whenLastPlaybackTime: moreThanMinimumTime,
            and: { sut in sut.setPreference(to: .restartFromBeginning) }
        )
    }
    
    func testStatus_shouldResumeFromLastSession_whenPreviousPlaybackMoreThanMinimum_andPreferResume() {
        let expectedTime = moreThanMinimumTime
        assertStatus(
            shouldBe: .resumeSession(playbackTime: expectedTime),
            whenLastPlaybackTime: expectedTime,
            and: { sut in sut.setPreference(to: .resumePreviousSession) }
        )
        
        assertStatus(
            shouldBe: .resumeSession(playbackTime: minimumTime),
            whenLastPlaybackTime: minimumTime,
            and: { sut in sut.setPreference(to: .resumePreviousSession) }
        )
    }
    
    func testPlaybackStopped_shouldNotSaveLastPlaybackTime_whenTimeLessThanMinimum() {
        let exitTime = lessThanMinimumTime
        makeSUT().playbackStopped(
            for: testFingerprint,
            on: exitTime,
            outOf: exitTime + completedThreshold
        )
        
        XCTAssertNil(mockPreviousSessionRepo.mockTimeIntervals[testFingerprint])
    }
    
    func testPlaybackStopped_shouldSaveLastPlaybackTime_whenTimeMoreThanMinimum() {
        let expectedTime = moreThanMinimumTime
        makeSUT().playbackStopped(
            for: testFingerprint,
            on: expectedTime,
            outOf: expectedTime + completedThreshold
        )
        
        XCTAssertEqual(mockPreviousSessionRepo.mockTimeIntervals[testFingerprint], expectedTime)
    }
    
    func testPlaybackStopped_shouldRemoveLastPlaybackTime_whenUnderCompletedPlaybackThreshold() {
        let expectedTime = moreThanMinimumTime
        let sut = makeSUT()
        
        sut.playbackStopped(
            for: testFingerprint,
            on: expectedTime,
            outOf: expectedTime + completedThreshold
        )
        
        sut.playbackStopped(
            for: testFingerprint,
            on: expectedTime + 1,
            outOf: expectedTime + completedThreshold
        )
        
        XCTAssertNil(mockPreviousSessionRepo.mockTimeIntervals[testFingerprint])
    }

    // MARK: - Helpers
    
    private func makeSUT() -> any PlaybackContinuationUseCaseProtocol {
        mockPreviousSessionRepo = MockPreviousPlaybackSessionRepository()
        return PlaybackContinuationUseCase(previousSessionRepo: mockPreviousSessionRepo)
    }
    
    private func assertStatus(
        shouldBe expectedStatus: PlaybackContinuationStatusEntity,
        whenLastPlaybackTime lastTimeInterval: TimeInterval?,
        and additionalAction: @escaping (any PlaybackContinuationUseCaseProtocol) -> Void = { _ in },
        line: UInt = #line
    ) {
        let sut = makeSUT()
        mockPreviousSessionRepo.mockTimeIntervals[testFingerprint] = lastTimeInterval
        additionalAction(sut)
        
        XCTAssertEqual(
            sut.status(for: testFingerprint),
            expectedStatus,
            line: line
        )
    }
    
    private var testFingerprint = "test-fingerprint"
}

private var minimumTime = PlaybackContinuationUseCase<MockPreviousPlaybackSessionRepository>.Constants.minimumContinuationPlaybackTime
private var completedThreshold = PlaybackContinuationUseCase<MockPreviousPlaybackSessionRepository>.Constants.completedPlaybackThreshold

private var lessThanMinimumTime: TimeInterval = TimeInterval(Int(minimumTime) - 1)
private var moreThanMinimumTime: TimeInterval = TimeInterval(Int(minimumTime) + 1)
