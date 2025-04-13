import Foundation
@testable import MEGA
import MEGADomain

final class MockSlideShowDataSource: SlideShowDataSourceProtocol {
    var count: Int { nodeEntities.count }
    
    var items: [Int: SlideShowCellViewModel] = [:]
    var loadSelectedPhotoPreviewCompletionHandler: (() -> Void)?
    var nodeEntities: [NodeEntity]
    var thumbnailUseCase: any ThumbnailUseCaseProtocol
    
    init(
        nodeEntities: [NodeEntity],
        thumbnailUseCase: any ThumbnailUseCaseProtocol
    ) {
        self.nodeEntities = nodeEntities
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    func resetData() {
        items.removeAll()
    }

    func sortNodes(byOrder order: SlideShowPlayingOrderEntity) {
        nodeEntities.sort { $0.modificationTime > $1.modificationTime }
    }
    
    func download(fromCurrentIndex index: Int) {
        
    }

    func loadSelectedPhotoPreview(completionHandler: (() -> Void)?) {
        loadSelectedPhotoPreviewCompletionHandler = completionHandler
    }

    func indexOfCurrentPhoto() -> Int {
        0
    }
}
