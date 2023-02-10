import Foundation
import MEGADomain
@testable import MEGA

final class MockSlideShowDataSource: SlideShowDataSourceProtocol {
    var photos = [SlideShowMediaEntity]() {
        didSet {
            if photos.count == 1 {
                initialPhotoDownloadCallback?()
            }
        }
    }
    
    var nodeEntities: [NodeEntity]
    var initialPhotoDownloadCallback: (() -> ())?
    var thumbnailUseCase: ThumbnailUseCaseProtocol
    
    init(
        nodeEntities: [NodeEntity],
        thumbnailUseCase: ThumbnailUseCaseProtocol
    ) {
        self.nodeEntities = nodeEntities
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    func resetData() {
        photos.removeAll()
        startInitialDownload(false)
    }
    
    func startInitialDownload(_ initialPhotoDownloaded: Bool) {
        processData(basedOnCurrentSlideIndex: 0, andOldSlideIndex: 0)
    }
    
    func loadSelectedPhotoPreview() -> Bool {
        true
    }
    
    func processData(basedOnCurrentSlideIndex currentSlideIndex: Int, andOldSlideIndex oldSlideIndex: Int) {
        nodeEntities.forEach { node in
            photos.append(SlideShowMediaEntity(image: nil, node: node, fileUrl: nil))
        }
    }
    
    func sortNodes(byOrder order: MEGADomain.SlideShowPlayingOrderEntity) {
        nodeEntities.sort { $0.modificationTime > $1.modificationTime }
    }
}
