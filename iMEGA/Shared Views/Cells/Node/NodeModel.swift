import Foundation

struct NodeModel {
    var name: String
    
    var handle: MEGAHandle
    var base64Handle: String
    
    var isFile: Bool
    var isFolder: Bool
    
    var hasThumbnail: Bool
    
    var isOutShare: Bool
    var isInShare: Bool
    var isExported: Bool
    var isTakenDown: Bool
    
    var isFavourite: Bool
    
    var label: NodeLabelTypeModel
    
    var size: UInt64
    var modificationTime: Date
    
    init(nodeEntity: NodeEntity) {
        name = nodeEntity.name
        
        handle = nodeEntity.handle
        base64Handle = nodeEntity.base64Handle
        
        isFile = nodeEntity.isFile
        isFolder = nodeEntity.isFolder
        
        hasThumbnail = nodeEntity.hasThumbnail
        
        isOutShare = nodeEntity.isOutShare
        isInShare = nodeEntity.isInShare
        isExported = nodeEntity.isExported
        isTakenDown = nodeEntity.isTakenDown
        isFavourite = nodeEntity.isFavourite
        label = NodeLabelTypeModel.init(nodeLabelTypeEntity: nodeEntity.label) ?? .unknown
        
        size = nodeEntity.size
        modificationTime = nodeEntity.modificationTime
    }
}

extension NodeModel: Equatable {
    static func == (lhs: NodeModel, rhs: NodeModel) -> Bool {
        lhs.base64Handle == rhs.base64Handle
    }
}
