import Foundation

final class PhotoBrowserDataProvider: NSObject {
    private var megaNodes: [MEGANode]?
    private var nodeEntities: [NodeEntity]?
    private let sdk: MEGASdk
    
    @objc var currentIndex: Int = 0
    
    @objc init(currentPhoto: MEGANode, allPhotos: [MEGANode], sdk: MEGASdk) {
        megaNodes = allPhotos
        self.sdk = sdk
        if let index = allPhotos.firstIndex(of: currentPhoto) {
            currentIndex = index
        }
        
        super.init()
    }
    
    @objc init(currentIndex: Int, allPhotos: [MEGANode], sdk: MEGASdk) {
        megaNodes = allPhotos
        self.sdk = sdk
        if allPhotos.indices ~= currentIndex {
            self.currentIndex = currentIndex
        }
        
        super.init()
    }
    
    init(currentPhoto: NodeEntity, allPhotos: [NodeEntity], sdk: MEGASdk) {
        nodeEntities = allPhotos
        self.sdk = sdk
        if let index = allPhotos.firstIndex(of: currentPhoto) {
            currentIndex = index
        }
        
        super.init()
    }
    
    @objc subscript(index: Int) -> MEGANode? {
        if let nodes = megaNodes {
            return nodes[safe: index]
        } else {
            return nodeEntities?[safe: index]?.toMEGANode(in: sdk)
        }
    }
    
    @objc var count: Int {
        if let nodes = megaNodes {
            return nodes.count
        } else {
            return nodeEntities?.count ?? 0
        }
    }
    
    @objc var currentPhoto: MEGANode? {
        if let nodes = megaNodes {
            return nodes[safe: currentIndex]
        } else {
            return nodeEntities?[safe: currentIndex]?.toMEGANode(in: sdk)
        }
    }
    
    @objc var allPhotos: [MEGANode] {
        if let nodes = megaNodes {
            return nodes
        } else {
            return nodeEntities?.toMEGANodes(in: sdk) ?? []
        }
    }
    
    @objc func shouldUpdateCurrentIndex(toIndex index: Int) -> Bool {
        currentIndex != index && isValid(index: index)
    }
    
    @objc func updatePhoto(by request: MEGARequest) {
        if megaNodes != nil, let node = request.toMEGANode(in: sdk), let index = megaNodes?.firstIndex(of: node) {
            megaNodes?[index] = node
        } else if let node = request.toNodeEntity(in: sdk), let index = nodeEntities?.firstIndex(of: node) {
            nodeEntities?[index] = node
        }
    }
    
    @objc func removePhotos(in nodeList: MEGANodeList) {
        if megaNodes != nil {
            removePhotosForMEGANodes(by: nodeList)
        } else {
            removePhotosForNodeEntities(by: nodeList)
        }
    }
    
    @objc func updatePhotos(in nodeList: MEGANodeList) {
        if megaNodes != nil {
            updatePhotosForMEGANodes(by: nodeList)
        } else {
            updatePhotosForNodeEntities(by: nodeList)
        }
    }
}

// MARK: - Private methods
extension PhotoBrowserDataProvider {
    private func isValid(index: Int) -> Bool {
        if let nodes = megaNodes {
            return nodes.indices ~= index
        } else if let nodes = nodeEntities {
            return nodes.indices ~= index
        } else {
            return false
        }
    }
    
    private func removePhotosForMEGANodes(by nodeList: MEGANodeList) {
        let photosSet = Set(megaNodes ?? [])
        let updatedSet = Set(nodeList.toNodeArray().removedChangeTypeNodes())
        let removedPhotos = photosSet.intersection(updatedSet)
        let preCurrentIndexPhotoSet = Set(megaNodes?.prefix(through: currentIndex) ?? [])
        
        for photo in removedPhotos {
            megaNodes?.remove(object: photo)
        }
        
        let preCurrentIndexRemovedPhotoCount = preCurrentIndexPhotoSet.intersection(removedPhotos).count
        currentIndex = max(currentIndex - preCurrentIndexRemovedPhotoCount, 0)
    }
    
    private func removePhotosForNodeEntities(by nodeList: MEGANodeList) {
        let photosSet = Set(nodeEntities ?? [])
        let updatedSet = Set(nodeList.toNodeEntities().removedChangeTypeNodes())
        let removedPhotos = photosSet.intersection(updatedSet)
        let preCurrentIndexPhotoSet = Set(nodeEntities?.prefix(through: currentIndex) ?? [])

        for photo in removedPhotos {
            nodeEntities?.remove(object: photo)
        }
        
        let preCurrentIndexRemovedPhotoCount = preCurrentIndexPhotoSet.intersection(removedPhotos).count
        currentIndex = max(currentIndex - preCurrentIndexRemovedPhotoCount, 0)
    }
    
    private func updatePhotosForMEGANodes(by nodeList: MEGANodeList) {
        let photosSet = Set(megaNodes ?? [])
        var updatedSet = Set(nodeList.toNodeArray().nodes(for: [.attributes, .publicLink]))
        updatedSet.formIntersection(photosSet)
        
        for photo in updatedSet {
            if let index = megaNodes?.firstIndex(of: photo) {
                megaNodes?[index] = photo
            }
        }
    }
    
    private func updatePhotosForNodeEntities(by nodeList: MEGANodeList) {
        let photosSet = Set(nodeEntities ?? [])
        var updatedSet = Set(nodeList.toNodeEntities().nodes(for: [.attributes, .publicLink]))
        updatedSet.formIntersection(photosSet)
        
        for photo in updatedSet {
            if let index = nodeEntities?.firstIndex(of: photo) {
                nodeEntities?[index] = photo
            }
        }
    }
}
