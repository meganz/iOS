import MEGAAppSDKRepo
import MEGASdk

public final class MockNode: MEGANode, @unchecked Sendable {
    private let nodeType: MEGANodeType
    private let nodeName: String
    private let nodeParentHandle: MEGAHandle
    private let nodeHandle: MEGAHandle
    private let nodeBase64Handle: String?
    private let changeType: MEGANodeChangeType
    private var nodeModificationTime: Date?
    private let _hasThumbnail: Bool
    private let isNodeDecrypted: Bool
    private let isNodeExported: Bool
    private let videoDuration: Int
    private let _label: MEGANodeLabel
    private let _isFavourite: Bool
    private let _fingerprint: String?
    private let _hasPreview: Bool
    let nodePath: String?
    private let _isTakenDown: Bool
    private let _isMarkedSensitive: Bool
    private let _description: String?
    private let _isInShare: Bool
    private let _tags: MockMEGAStringList?

    public init(handle: MEGAHandle,
                nodeBase64Handle: String? = nil,
                name: String = "",
                nodeType: MEGANodeType = .file,
                parentHandle: MEGAHandle = .invalidHandle,
                changeType: MEGANodeChangeType = .new,
                modificationTime: Date? = nil,
                hasThumbnail: Bool = false,
                nodePath: String? = nil,
                isNodeDecrypted: Bool = false,
                isNodeExported: Bool = false,
                duration: Int = 0,
                label: MEGANodeLabel = .unknown,
                isFavourite: Bool = false,
                fingerprint: String? = nil,
                hasPreview: Bool = false,
                isTakenDown: Bool = false,
                isMarkedSensitive: Bool = false,
                description: String? = nil,
                tags: MockMEGAStringList? = nil,
                isInShare: Bool = false
    ) {
        nodeHandle = handle
        self.nodeBase64Handle = nodeBase64Handle
        nodeName = name
        self.nodeType = nodeType
        nodeParentHandle = parentHandle
        self.changeType = changeType
        nodeModificationTime = modificationTime
        _hasThumbnail = hasThumbnail
        self.nodePath = nodePath
        self.isNodeDecrypted = isNodeDecrypted
        self.isNodeExported = isNodeExported
        self.videoDuration = duration
        _label = label
        _isFavourite = isFavourite
        self._fingerprint = fingerprint
        _hasPreview = hasPreview
        _isTakenDown = isTakenDown
        _isMarkedSensitive = isMarkedSensitive
        _description = description
        _tags = tags
        _isInShare = isInShare
        super.init()
    }
    
    public override var handle: MEGAHandle { nodeHandle }
    
    public override var type: MEGANodeType { nodeType }
    
    public override var duration: Int { videoDuration }
    
    public override func getChanges() -> MEGANodeChangeType { changeType }
    
    public override func hasChangedType(_ changeType: MEGANodeChangeType) -> Bool {
        self.changeType.rawValue & changeType.rawValue > 0
    }
    
    public override func isFile() -> Bool { nodeType == .file }
    
    public override func isFolder() -> Bool { nodeType == .folder }
    
    public override var name: String! { nodeName }
    
    public override var parentHandle: MEGAHandle { nodeParentHandle }
    
    public override var modificationTime: Date? { nodeModificationTime }
    
    public override func hasThumbnail() -> Bool { _hasThumbnail }
    
    public override func isExported() -> Bool { isNodeExported }
        
    public override var label: MEGANodeLabel { _label }
    
    public override var isFavourite: Bool { _isFavourite }
    
    public override var fingerprint: String? { _fingerprint }
    
    public override func hasPreview() -> Bool { _hasPreview }

    public override var base64Handle: String? { nodeBase64Handle }
    
    public override func isTakenDown() -> Bool { _isTakenDown }
    
    public override var isMarkedSensitive: Bool { _isMarkedSensitive }

    public override var description: String? { _description }

    public override func isInShare() -> Bool { _isInShare }

    public override var tags: MEGAStringList? { _tags }
}
