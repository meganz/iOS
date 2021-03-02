struct NodeEntity {

    // MARK: - Types

    let changeTypes: ChangeType
    let nodeType: NodeType?

    // MARK: - Identification

    let name: String
    let fingerprint: String?
    let tag: Int

    // MARK: - Handles

    let handle: MEGAHandle
    let base64Handle: String
    let restoreParentHandle: MEGAHandle
    let ownerHandle: MEGAHandle

    // MARK: - Attributes

    let isFile: Bool
    let isFolder: Bool
    let isRemoved: Bool
    let hasThumnail: Bool
    let hasPreview: Bool
    let isPublic: Bool
    let isShare: Bool
    let isOutShare: Bool
    let isInShare: Bool
    let isExported: Bool
    let isExpired: Bool
    let isTakenDown: Bool

    // MARK: - Link

    let publicHandle: MEGAHandle
    let expirationTime: Date?
    let publicLinkCreationTime: Date?

    // MARK: - File

    let size: Decimal
    let createTime: Date?
    let modificationTime: Date

    // MARK: - Media

    let width: Int
    let height: Int
    let shortFormat: Int
    let codecId: Int
    let duration: Int

    // MARK: - Photo

    let latitude: Double?
    let longitude: Double?


    enum NodeType: Int {
        case unknown    = -1
        case file       = 0
        case folder
        case root
        case incoming
        case rubbish

        init?(with megaNodeType: MEGANodeType) {
            self.init(rawValue: megaNodeType.rawValue)
        }
    }

    struct ChangeType: OptionSet {
        let rawValue: UInt

        static let removed          = ChangeType(rawValue: 1 << 1)
        static let attributes       = ChangeType(rawValue: 1 << 2)
        static let owner            = ChangeType(rawValue: 1 << 3)
        static let timestamp        = ChangeType(rawValue: 1 << 4)
        static let fileAttributes   = ChangeType(rawValue: 1 << 5)
        static let inShare          = ChangeType(rawValue: 1 << 6)
        static let outShare         = ChangeType(rawValue: 1 << 7)
        static let parent           = ChangeType(rawValue: 1 << 8)
        static let pendingShare     = ChangeType(rawValue: 1 << 9)
        static let publicLink       = ChangeType(rawValue: 1 << 10)
        static let new              = ChangeType(rawValue: 1 << 11)
    }
}

extension NodeEntity {

    init(with node: MEGANode) {

        // MARK: - Types
        self.changeTypes                        = ChangeType.init(rawValue: node.getChanges().rawValue)
        self.nodeType                           = NodeType(with: node.type)

        // MARK: - Identification

        self.name                               = node.name
        self.tag                                = node.tag
        self.fingerprint                        = node.fingerprint

        // MARK: - Handles

        self.handle                             = node.handle
        self.base64Handle                       = node.base64Handle
        self.ownerHandle                        = node.owner
        self.restoreParentHandle                = node.restoreHandle

        // MARK: - Attributes

        self.isFile                             = node.isFile()
        self.isFolder                           = node.isFolder()
        self.isRemoved                          = node.isRemoved()
        self.hasThumnail                        = node.hasThumbnail()
        self.hasPreview                         = node.hasPreview()
        self.isPublic                           = node.isPublic()
        self.isShare                            = node.isShared()
        self.isOutShare                         = node.isOutShare()
        self.isInShare                          = node.isInShare()
        self.isExported                         = node.isExported()
        self.isExpired                          = node.isExpired()
        self.isTakenDown                        = node.isTakenDown()

        // MARK: - Links

        self.publicHandle                       = node.publicHandle
        self.expirationTime                     = Date(timeIntervalSince1970: TimeInterval(node.expirationTime))
        self.publicLinkCreationTime             = node.publicLinkCreationTime

        // MARK: - Files

        self.size                               = node.size.decimalValue
        self.createTime                         = node.creationTime
        self.modificationTime                   = node.modificationTime

        // MARK: - Media

        self.width                              = node.width
        self.height                             = node.height
        self.shortFormat                        = node.shortFormat
        self.codecId                            = node.videoCodecId
        self.duration                           = node.duration

        // MARK: - Photo

        self.latitude                           = node.latitude?.doubleValue
        self.longitude                          = node.longitude?.doubleValue
    }
}
