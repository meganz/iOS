import Foundation
import MEGADomain
@testable import MEGA

final class MockPhotoBrowserDataProvider: PhotoBrowserDataProviderProtocol {
    private var nodeEntities: [NodeEntity]?
    private var currentPhotoEntity: NodeEntity
    private var sdk: MEGASdk
    
    init(currentPhoto: NodeEntity, allPhotos: [NodeEntity], sdk: MEGASdk) {
        currentPhotoEntity = currentPhoto
        nodeEntities = allPhotos
        self.sdk = sdk
    }
    
    var allPhotoEntities: [NodeEntity] {
        nodeEntities ?? [NodeEntity]()
    }
    
    var currentPhoto: MEGANode? {
        MEGANode()
    }
}
