@testable import MEGA
import MEGADomain
import XCTest

@MainActor
final class CallParticipantCellTests: XCTestCase {
    func testConfigureForParticipant_forParticipantIsNotScreenShareCell_shouldNotHideNameLabel() {
        let sut = makeCallParticipantCell()

        let participant = CallParticipantEntity()
        participant.isScreenShareCell = false
        sut.configure(for: participant, in: .grid)
        
        XCTAssertFalse(sut.nameLabel.isHidden)
    }
    
    func testConfigureForParticipant_forParticipantIsScreenShareCell_shouldHideNameLabel() {
        let sut = makeCallParticipantCell()

        let participant = CallParticipantEntity()
        participant.isScreenShareCell = true
        sut.configure(for: participant, in: .grid)
        
        XCTAssertTrue(sut.nameLabel.isHidden)
    }
    
    func testConfigureForParticipant_forParticipantIsNotScreenShareCellAndVideoIsOn_shouldNotHideVideoImageAndHideAvatar() {
        let sut = makeCallParticipantCell()

        let participant = CallParticipantEntity()
        participant.isScreenShareCell = false
        participant.video = .on
        sut.configure(for: participant, in: .grid)
        
        XCTAssertFalse(sut.videoImageView.isHidden)
        XCTAssertTrue(sut.avatarImageView.isHidden)
    }
    
    func testConfigureForParticipant_forParticipantIsNotScreenShareCellAndVideoIsNotOn_shouldHideVideoImageAndNotHideAvatar() {
        let sut = makeCallParticipantCell()

        let participant = CallParticipantEntity()
        participant.isScreenShareCell = false
        participant.video = .off
        sut.configure(for: participant, in: .grid)
        
        XCTAssertTrue(sut.videoImageView.isHidden)
        XCTAssertFalse(sut.avatarImageView.isHidden)
    }
    
    func testConfigureForParticipant_forParticipantIsScreenShareCell_shouldNotHideVideoImageAndHideAvatar() {
        let sut = makeCallParticipantCell()

        let participant = CallParticipantEntity()
        participant.isScreenShareCell = true
        sut.configure(for: participant, in: .grid)
        
        XCTAssertFalse(sut.videoImageView.isHidden)
        XCTAssertTrue(sut.avatarImageView.isHidden)
    }
    
    // MARK: - Private methods
    
    private func makeCallParticipantCell() -> CallParticipantCell {
        let nib = UINib(nibName: "CallParticipantCell", bundle: nil)
        guard let sut = nib.instantiate(withOwner: nil, options: nil).first as? CallParticipantCell else {
            XCTFail("CallParticipantCell should not be nil")
            return CallParticipantCell()
        }
        return sut
    }
}
