import Combine
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
@testable import Video
import XCTest

final class VideoSelectionCheckmarkUIUpdateAdapterTests: XCTestCase {
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - onTappedCheckMark
    
    func testOnTappedCheckMark_whenNotEditingState_doesNotToggleSelection() {
        let node = anyNode(id: 1)
        let selection = VideoSelection()
        let cellViewModel = VideoCellViewModel(
            mode: .plain,
            viewContext: .allVideos,
            nodeEntity: node,
            thumbnailLoader: MockThumbnailLoader(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            onTapMoreOptions: { _ in },
            onTapped: { _ in }
        )
        let sut = VideoSelectionCheckmarkUIUpdateAdapter(
            selection: selection,
            viewModel: cellViewModel
        )
        selection.editMode = .inactive
        selection.isSelectionDisabled = true
        let exp = expectation(description: "Wait for subscriptions")
        var receivedIsSelected = false
        cellViewModel.$isSelected
            .dropFirst()
            .sink { isSelected in
                receivedIsSelected = isSelected
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.onTappedCheckMark()
        wait(for: [exp], timeout: 0.2)
        
        XCTAssertFalse(receivedIsSelected)
    }
    
    func testOnTappedCheckMark_whenInEditingState_toggleSelection() {
        let node = anyNode(id: 1)
        let selection = VideoSelection()
        let cellViewModel = VideoCellViewModel(
            mode: .plain,
            viewContext: .allVideos,
            nodeEntity: node,
            thumbnailLoader: MockThumbnailLoader(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            onTapMoreOptions: { _ in },
            onTapped: { _ in }
        )
        let sut = VideoSelectionCheckmarkUIUpdateAdapter(
            selection: selection,
            viewModel: cellViewModel
        )
        selection.editMode = .active
        selection.isSelectionDisabled = false
        let exp = expectation(description: "Wait for subscriptions")
        exp.expectedFulfillmentCount = 2
        var receivedIsSelected = false
        cellViewModel.$isSelected
            .dropFirst()
            .sink { isSelected in
                receivedIsSelected = isSelected
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.onTappedCheckMark()
        wait(for: [exp], timeout: 0.2)
        
        XCTAssertTrue(receivedIsSelected)
    }
    
    // MARK: - Helpers
    
    private func anyNode(id: HandleEntity) -> NodeEntity {
        NodeEntity(
            changeTypes: .new,
            nodeType: .file,
            name: "some-name",
            handle: id,
            isFile: true,
            hasThumbnail: true,
            hasPreview: true,
            label: .unknown,
            publicHandle: id,
            size: 2,
            duration: 2,
            mediaType: .video
        )
    }
}
