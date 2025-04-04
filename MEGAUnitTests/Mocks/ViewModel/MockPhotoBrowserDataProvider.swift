import Foundation
@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain

final class MockPhotoBrowserDataProvider: PhotoBrowserDataProviderProtocol, @unchecked Sendable {
    
    private var nodeEntities: [NodeEntity]?
    private var currentPhotoEntity: NodeEntity
    private var sdk: MEGASdk
    
    init(currentPhoto: NodeEntity, allPhotos: [NodeEntity], sdk: MEGASdk, nodeProvider: any MEGANodeProviderProtocol) {
        currentPhotoEntity = currentPhoto
        nodeEntities = allPhotos
        self.sdk = sdk
    }
    
    var allPhotoEntities: [NodeEntity] {
        nodeEntities ?? [NodeEntity]()
    }
    
    var currentPhoto: MEGANode? {
        currentPhotoEntity.toMEGANode(in: sdk)
    }
        
    func currentPhoto() async -> MEGANode? {
        currentPhotoEntity.toMEGANode(in: sdk)
    }
}
