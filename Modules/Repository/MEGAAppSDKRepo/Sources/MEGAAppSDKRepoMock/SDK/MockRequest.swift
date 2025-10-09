import MEGAAppSDKRepo
import MEGASdk

public final class MockRequest: MEGARequest, @unchecked Sendable {
    private let handle: MEGAHandle
    private let requestType: MEGARequestType
    private let parameterType: MEGAUserAttribute
    
    private let _set: MEGASet?
    private let _text: String?
    private let _parentHandle: UInt64
    private let _elementsInSet: [MEGASetElement]
    private let _number: Int64
    private let _link: String?
    private let _flag: Bool
    private let _publicNode: MEGANode?
    private let _backupInfoList: [MEGABackupInfo]
    private let stringDict: [String: String]
    private let stringListDictionary: [String: MEGAStringList]
    private let _file: String?
    private let _accountDetails: MEGAAccountDetails?
    private let _numDetails: Int
    private let _notifications: MEGANotificationList?
    private let _recentActionsBuckets: [MEGARecentActionBucket]?
    private let _name: String?
    private let _folderInfo: MEGAFolderInfo?
    private let _transferredBytes: Int64
    private let _totalBytes: Int64
    
    public init(
        handle: MEGAHandle,
        requestType: MEGARequestType = .MEGARequestTypeLogin,
        parameterType: MEGAUserAttribute = .avatar,
        set: MEGASet? = nil,
        text: String? = nil,
        parentHandle: MEGAHandle = .invalidHandle,
        elementInSet: [MEGASetElement] = [],
        number: Int64 = 0,
        link: String? = nil,
        flag: Bool = false,
        publicNode: MEGANode? = nil,
        backupInfoList: [MEGABackupInfo] = [],
        stringDict: [String: String] = [:],
        stringListDictionary: [String: MEGAStringList] = [:],
        file: String? = nil,
        accountDetails: MEGAAccountDetails? = nil,
        numDetails: Int = 0,
        notifications: MEGANotificationList? = nil,
        recentActionsBuckets: [MEGARecentActionBucket] = [],
        name: String? = nil,
        folderInfo: MEGAFolderInfo? = nil,
        transferredBytes: Int64 = 0,
        totalBytes: Int64 = 0
    ) {
        self.handle = handle
        self.requestType = requestType
        self.parameterType = parameterType
        
        _set = set
        _text = text
        _parentHandle = parentHandle
        _elementsInSet = elementInSet
        _number = number
        _link = link
        _flag = flag
        _publicNode = publicNode
        _backupInfoList = backupInfoList
        self.stringDict = stringDict
        self.stringListDictionary = stringListDictionary
        _file = file
        _accountDetails = accountDetails
        _numDetails = numDetails
        _notifications = notifications
        _recentActionsBuckets = recentActionsBuckets
        _name = name
        _folderInfo = folderInfo
        _transferredBytes = transferredBytes
        _totalBytes = totalBytes
        
        super.init()
    }
    
    public override var type: MEGARequestType { requestType }
    public override var paramType: Int { parameterType.rawValue }
    public override var nodeHandle: MEGAHandle { handle }
    public override var set: MEGASet? { _set }
    public override var text: String? { _text }
    public override var parentHandle: UInt64 { _parentHandle }
    public override var elementsInSet: [MEGASetElement] { _elementsInSet }
    public override var number: Int64 { _number }
    public override var link: String? { _link }
    public override var flag: Bool { _flag }
    public override var publicNode: MEGANode? { _publicNode }
    public override var backupInfoList: [MEGABackupInfo] { _backupInfoList }
    public override var megaStringDictionary: [String: String] { stringDict }
    public override var file: String? { _file }
    public override var megaAccountDetails: MEGAAccountDetails? { _accountDetails }
    public override var numDetails: Int { _numDetails }
    public override var megaNotifications: MEGANotificationList? { _notifications }
    public override var recentActionsBuckets: [MEGARecentActionBucket]? { _recentActionsBuckets }
    public override var name: String? { _name }
    public override var megaFolderInfo: MEGAFolderInfo? { _folderInfo }
    public override var megaStringListDictionary: [String: MEGAStringList]? { stringListDictionary }
    public override var transferredBytes: Int64 { _transferredBytes }
    public override var totalBytes: Int64 { _totalBytes }
}
