import MEGADomain
import MEGADomainMock
import XCTest

final class PlaybackContinuationUseCaseTests: XCTestCase {
    
    private var mockPreviousSessionRepo: MockPreviousPlaybackSessionRepository!
    
    func testStatus_whenPreviousPlaybackLessThanMinimum_shouldStartFromBeginning() {
        assertStatus(shouldBe: .startFromBeginning, whenLastPlaybackTime: nil)
        assertStatus(shouldBe: .startFromBeginning, whenLastPlaybackTime: lessThanMinimumTime)
    }
    
    func testStatus_whenPreviousPlaybackMoreThanMinimum_andHasNoPreference_shouldDisplayDialog() {
        let expectedTime = moreThanMinimumTime
        assertStatus(shouldBe: .displayDialog(playbackTime: expectedTime), whenLastPlaybackTime: expectedTime)
        assertStatus(shouldBe: .displayDialog(playbackTime: minimumTime), whenLastPlaybackTime: minimumTime)
    }
    
    func testStatus_whenPreviousPlaybackMoreThanMinimum_andPreferRestart_shouldStartFromBeginning() {
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
    
    func testStatus_whenPreviousPlaybackMoreThanMinimum_andPreferResume_shouldResumeFromLastSession() {
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
    
    func testPlaybackStopped_whenTimeLessThanMinimum_shouldNotSaveLastPlaybackTime() {
        let exitTime = lessThanMinimumTime
        makeSUT().playbackStopped(
            for: testFingerprint,
            on: exitTime,
            outOf: exitTime + completedThreshold
        )
        
        XCTAssertNil(mockPreviousSessionRepo.mockTimeIntervals[testFingerprint])
    }
    
    func testPlaybackStopped_whenTimeMoreThanMinimum_shouldSaveLastPlaybackTime() {
        let expectedTime = moreThanMinimumTime
        makeSUT().playbackStopped(
            for: testFingerprint,
            on: expectedTime,
            outOf: expectedTime + completedThreshold
        )
        
        XCTAssertEqual(mockPreviousSessionRepo.mockTimeIntervals[testFingerprint], expectedTime)
    }
    
    func testPlaybackStopped_whenUnderCompletedPlaybackThreshold_shouldRemoveLastPlaybackTime() {
        let stopTime = moreThanMinimumTime
        let sut = makeSUT()

        mockPreviousSessionRepo.mockTimeIntervals[testFingerprint] = moreThanMinimumTime
        
        sut.playbackStopped(
            for: testFingerprint,
            on: stopTime,
            outOf: stopTime - 1 + completedThreshold
        )
        
        XCTAssertNil(mockPreviousSessionRepo.mockTimeIntervals[testFingerprint])
    }

    func testPlaybackStopped_whenUnderMinimumPlaybackThreshold_shouldRemoveLastPlaybackTime() {
        let sut = makeSUT()

        mockPreviousSessionRepo.mockTimeIntervals[testFingerprint] = moreThanMinimumTime

        sut.playbackStopped(
            for: testFingerprint,
            on: lessThanMinimumTime,
            outOf: moreThanMinimumTime
        )

        XCTAssertNil(mockPreviousSessionRepo.mockTimeIntervals[testFingerprint])
    }

    // MARK: - Custom minimum playback time

    func testStatus_whenCustomMinimum_andPreviousPlaybackMoreThanMinimum_shouldDisplayDialog() {
        let expectedTime = moreThanRevampMinimumTime
        assertStatus(
            shouldBe: .displayDialog(playbackTime: expectedTime),
            whenLastPlaybackTime: expectedTime,
            minimumPlaybackTime: revampMinimumTime
        )
    }

    func testStatus_whenCustomMinimum_andPreviousPlaybackLessThanMinimum_shouldStartFromBeginning() {
        assertStatus(
            shouldBe: .startFromBeginning,
            whenLastPlaybackTime: lessThanRevampMinimumTime,
            minimumPlaybackTime: revampMinimumTime
        )
    }

    func testPlaybackStopped_whenCustomMinimum_andTimeMoreThanMinimum_shouldSaveLastPlaybackTime() {
        let expectedTime = moreThanRevampMinimumTime
        let sut = makeSUT(minimumPlaybackTime: revampMinimumTime)
        sut.playbackStopped(
            for: testFingerprint,
            on: expectedTime,
            outOf: expectedTime + completedThreshold
        )

        XCTAssertEqual(mockPreviousSessionRepo.mockTimeIntervals[testFingerprint], expectedTime)
    }

    func testPlaybackStopped_whenCustomMinimum_andTimeLessThanMinimum_shouldNotSaveLastPlaybackTime() {
        let exitTime = lessThanRevampMinimumTime
        makeSUT(minimumPlaybackTime: revampMinimumTime).playbackStopped(
            for: testFingerprint,
            on: exitTime,
            outOf: exitTime + completedThreshold
        )

        XCTAssertNil(mockPreviousSessionRepo.mockTimeIntervals[testFingerprint])
    }

    // MARK: - Helpers

    private func makeSUT(
        minimumPlaybackTime: TimeInterval = Constants.minimumContinuationPlaybackTime
    ) -> any PlaybackContinuationUseCaseProtocol {
        mockPreviousSessionRepo = MockPreviousPlaybackSessionRepository()
        return PlaybackContinuationUseCase(
            previousSessionRepo: mockPreviousSessionRepo,
            minimumPlaybackTime: minimumPlaybackTime
        )
    }

    private func assertStatus(
        shouldBe expectedStatus: PlaybackContinuationStatusEntity,
        whenLastPlaybackTime lastTimeInterval: TimeInterval?,
        minimumPlaybackTime: TimeInterval = Constants.minimumContinuationPlaybackTime,
        and additionalAction: @escaping (any PlaybackContinuationUseCaseProtocol) -> Void = { _ in },
        line: UInt = #line
    ) {
        let sut = makeSUT(minimumPlaybackTime: minimumPlaybackTime)
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

private typealias Constants = PlaybackContinuationUseCase<MockPreviousPlaybackSessionRepository>.Constants

private let minimumTime = Constants.minimumContinuationPlaybackTime
private let completedThreshold = Constants.completedPlaybackThreshold

private let lessThanMinimumTime: TimeInterval = TimeInterval(Int(minimumTime) - 1)
private let moreThanMinimumTime: TimeInterval = TimeInterval(Int(minimumTime) + 1)

private let revampMinimumTime = Constants.minimumContinuationPlaybackTimeRevamp
private let lessThanRevampMinimumTime: TimeInterval = TimeInterval(Int(revampMinimumTime) - 1)
private let moreThanRevampMinimumTime: TimeInterval = TimeInterval(Int(revampMinimumTime) + 1)
