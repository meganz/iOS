import MEGASdk
import MEGASDKRepo

public typealias MockSdkRequestResult = Result<MEGARequest, MEGAError>

public final class MockSdk: MEGASdk {
    private var fileLinkNode: MEGANode?
    private var nodes: [MEGANode]
    private let rubbishNodes: [MEGANode]
    private let syncDebrisNodes: [MEGANode]
    private let backupInfoList: [MEGABackupInfo]
    private let _deviceId: String?
    private let myContacts: MEGAUserList
    public var _myUser: MEGAUser?
    public var _isLoggedIn: Int
    public var _isMasterBusinessAccount: Bool
    public var _isAchievementsEnabled: Bool
    public var _isNewAccount: Bool
    public var _isContactVerificationWarningEnabled: Bool
    private let _bandwidthOverquotaDelay: Int64
    private let email: String?
    private let megaRootNode: MEGANode?
    private let rubbishBinNode: MEGANode?
    private let sets: [MEGASet]
    private let setElements: [MEGASetElement]
    private let megaSetElementCounts: [MEGAHandle: UInt]
    private let nodeList: MEGANodeList
    private let shareList: MEGAShareList
    private let isSharedFolderOwnerVerified: Bool
    private let sharedFolderOwner: MEGAUser?
    private let incomingNodes: MEGANodeList
    private let outgoingNodes: MEGANodeList
    private let publicLinkNodes: MEGANodeList
    private let createSupportTicketError: MEGAErrorType
    private let link: String?
    private let megaSetError: MEGAErrorType
    private let _incomingContactRequests: MEGAContactRequestList
    private let _userAlertList: MEGAUserAlertList
    private let _upgradeSecurity: (MEGASdk, any MEGARequestDelegate) -> Void
    private let _accountDetails: (MEGASdk, any MEGARequestDelegate) -> Void
    private let smsState: SMSState
    private let devices: [String: String]
    private let file: String?
    private let copiedNodeHandles: [MEGAHandle: MEGAHandle]
    private let abTestValues: [String: Int]
    private let remoteFeatureFlagValues: [String: Int]
    private let requestResult: MockSdkRequestResult
    private let _accountCreationDate: Date?
    private let _enabledNotificationIdList: MEGAIntegerList?
    private var _lastReadNotificationId: Int32
    private var _isNodeInheritingSensitivity: Bool
    private var _hasVersionsForNode: Bool
    private let setUserAttributeTypeMegaSetError: (MEGAUserAttribute) -> MEGAErrorType
    private let _outgoingContactRequests: MEGAContactRequestList
    private let createdFolderHandle: MEGAHandle?
    private let nodeFingerprint: String?
    private let nodeSizes: [MEGAHandle: Int64]
    private let folderInfo: MEGAFolderInfo?
    
    public private(set) var sendEvent_Calls = [(
        eventType: Int,
        message: String,
        addJourneyId: Bool,
        viewId: String?
    )]()
    
    public private(set) var nodeForHandleCallCount = 0
    public private(set) var messages = [Message]()
    public private(set) var searchQueryParameters: SearchQueryParameters?
    public private(set) var nodeListSearchCallCount = 0
    public private(set) var searchWithFilterCallCount = 0
    public private(set) var searchNonRecursivelyWithFilterCallCount = 0
    public private(set) var isNodeSensitive: Bool?
    public private(set) var megaSetsCallCount = 0
    public private(set) var copyNodeWithNewNameCallCount = 0
    public private(set) var copyNodeWithSameNameCallCount = 0
    public private(set) var moveNodeWithNewNameCallCount = 0
    public private(set) var moveNodeWithSameNameCallCount = 0
    
    public enum Message: Equatable, Hashable {
        case publicNodeForMegaFileLink(String)
        case createSetElement(_ sid: MEGAHandle, nodeId: MEGAHandle, name: String?)
        case removeSet(sid: MEGAHandle)
        case createSet(name: String?, type: MEGASetType)
        case updateSetName(sid: MEGAHandle, name: String)
    }
    
    public var hasGlobalDelegate = false
    public var hasRequestDelegate = false
    public var hasTransferDelegate = false
    public var addMEGADelegateCallCount = 0
    public var removeMEGADelegateCallCount = 0
    public var apiURL: String?
    public var disablepkp: Bool?
    public var shareAccessLevel: MEGAShareType
    public var stopPublicSetPreviewCalled = 0
    public var authorizeNodeCalled = 0
    public var getRecentActionsAsyncCalled = false
    public var delegateQueueType: ListenerQueueType?
    public var contentConsumptionPreferences: [String: String]
    
    public init(fileLinkNode: MEGANode? = nil,
                nodes: [MEGANode] = [],
                rubbishNodes: [MEGANode] = [],
                syncDebrisNodes: [MEGANode] = [],
                incomingNodes: MEGANodeList = MEGANodeList(),
                outgoingNodes: MEGANodeList = MEGANodeList(),
                publicLinkNodes: MEGANodeList = MEGANodeList(),
                backupInfoList: [MEGABackupInfo] = [],
                deviceId: String? = nil,
                myContacts: MEGAUserList = MEGAUserList(),
                myUser: MEGAUser? = nil,
                isLoggedIn: Int = 0,
                isMasterBusinessAccount: Bool = false,
                isAchievementsEnabled: Bool = false,
                isNewAccount: Bool = false,
                isContactVerificationWarningEnabled: Bool = false,
                bandwidthOverquotaDelay: Int64 = 0,
                smsState: SMSState = .notAllowed,
                myEmail: String? = nil,
                megaSets: [MEGASet] = [],
                megaSetElements: [MEGASetElement] = [],
                megaRootNode: MEGANode? = nil,
                rubbishBinNode: MEGANode? = nil,
                megaSetElementCounts: [MEGAHandle: UInt] = [:],
                nodeList: MEGANodeList = MEGANodeList(),
                shareList: MEGAShareList = MEGAShareList(),
                isSharedFolderOwnerVerified: Bool = false,
                sharedFolderOwner: MEGAUser? = nil,
                createSupportTicketError: MEGAErrorType = .apiOk,
                link: String? = nil,
                megaSetError: MEGAErrorType = .apiOk,
                incomingContactRequestList: MEGAContactRequestList = MEGAContactRequestList(),
                userAlertList: MEGAUserAlertList = MEGAUserAlertList(),
                upgradeSecurity: @escaping (MEGASdk, any MEGARequestDelegate) -> Void = { _, _ in },
                accountDetails: @escaping (MEGASdk, any MEGARequestDelegate) -> Void = { _, _ in },
                devices: [String: String] = [:],
                contentConsumptionPreferences: [String: String] = [:],
                file: String? = nil,
                copiedNodeHandles: [MEGAHandle: MEGAHandle] = [:],
                abTestValues: [String: Int] = [:],
                remoteFeatureFlagValues: [String: Int] = [:],
                requestResult: MockSdkRequestResult = .failure(MockError.failingError),
                accountCreationDate: Date? = nil,
                enabledNotificationIdList: MEGAIntegerList? = nil,
                lastReadNotificationId: Int32 = 0,
                isNodeInheritingSensitivity: Bool = false,
                hasVersionsForNode: Bool = false,
                setUserAttributeTypeMegaSetError: @escaping (MEGAUserAttribute) -> MEGAErrorType = { _ in .apiOk },
                outgoingContactRequests: MEGAContactRequestList = MEGAContactRequestList(),
                createdFolderHandle: MEGAHandle? = nil,
                shareAccessLevel: MEGAShareType = .accessUnknown,
                nodeFingerprint: String? = nil,
                nodeSizes: [MEGAHandle: Int64] = [:],
                folderInfo: MEGAFolderInfo? = nil
    ) {
        self.fileLinkNode = fileLinkNode
        self.nodes = nodes
        self.rubbishNodes = rubbishNodes
        self.syncDebrisNodes = syncDebrisNodes
        self.backupInfoList = backupInfoList
        _deviceId = deviceId
        self.myContacts = myContacts
        _myUser = myUser
        _isLoggedIn = isLoggedIn
        _isMasterBusinessAccount = isMasterBusinessAccount
        _isAchievementsEnabled = isAchievementsEnabled
        _isNewAccount = isNewAccount
        _isContactVerificationWarningEnabled = isContactVerificationWarningEnabled
        _bandwidthOverquotaDelay = bandwidthOverquotaDelay
        self.smsState = smsState
        email = myEmail
        sets = megaSets
        setElements = megaSetElements
        self.megaRootNode = megaRootNode
        self.rubbishBinNode = rubbishBinNode
        self.megaSetElementCounts = megaSetElementCounts
        self.nodeList = nodeList
        self.shareList = shareList
        self.isSharedFolderOwnerVerified = isSharedFolderOwnerVerified
        self.sharedFolderOwner = sharedFolderOwner
        self.incomingNodes = incomingNodes
        self.outgoingNodes = outgoingNodes
        self.publicLinkNodes = publicLinkNodes
        self.createSupportTicketError = createSupportTicketError
        self.link = link
        self.megaSetError = megaSetError
        self._incomingContactRequests = incomingContactRequestList
        _userAlertList = userAlertList
        _upgradeSecurity = upgradeSecurity
        _accountDetails = accountDetails
        self.devices = devices
        self.contentConsumptionPreferences = contentConsumptionPreferences
        self.file = file
        self.copiedNodeHandles = copiedNodeHandles
        self.abTestValues = abTestValues
        self.remoteFeatureFlagValues = remoteFeatureFlagValues
        self.requestResult = requestResult
        self._accountCreationDate = accountCreationDate
        _enabledNotificationIdList = enabledNotificationIdList
        _lastReadNotificationId = lastReadNotificationId
        _isNodeInheritingSensitivity = isNodeInheritingSensitivity
        _hasVersionsForNode = hasVersionsForNode
        self.setUserAttributeTypeMegaSetError = setUserAttributeTypeMegaSetError
        _outgoingContactRequests = outgoingContactRequests
        self.createdFolderHandle = createdFolderHandle
        self.shareAccessLevel = shareAccessLevel
        self.nodeFingerprint = nodeFingerprint
        self.nodeSizes = nodeSizes
        self.folderInfo = folderInfo
        super.init()
    }
    
    public func setNodes(_ nodes: [MEGANode]) { self.nodes = nodes }
    
    public func setShareAccessLevel(_ shareAccessLevel: MEGAShareType) {
        self.shareAccessLevel = shareAccessLevel
    }
    
    public override var myUser: MEGAUser? { _myUser }
    
    public override var myEmail: String? { email }
    
    public override var totalNodes: UInt64 { UInt64(nodes.count) }
    
    public override var bandwidthOverquotaDelay: Int64 { _bandwidthOverquotaDelay }

    public override var isContactVerificationWarningEnabled: Bool { _isContactVerificationWarningEnabled }
    
    public override var isNewAccount: Bool { _isNewAccount }
    
    public override var accountCreationDate: Date? { _accountCreationDate }
    
    public override func node(forHandle handle: MEGAHandle) -> MEGANode? {
        nodeForHandleCallCount += 1
        return nodes.first { $0.handle == handle }
    }
    
    public override func node(forFingerprint fingerprint: String) -> MEGANode? {
        nodes.first { $0.fingerprint == fingerprint }
    }
    
    public override func fingerprint(forFilePath filePath: String) -> String? {
        nodeFingerprint
    }
    
    public override func parentNode(for node: MEGANode) -> MEGANode? {
        nodes.first { $0.handle == node.parentHandle }
    }
    
    public override func isNode(inRubbish node: MEGANode) -> Bool {
        rubbishNodes.contains(node)
    }
    
    public override func children(forParent parent: MEGANode) -> MEGANodeList {
        let children = nodes.filter { $0.parentHandle == parent.handle }
        return MockNodeList(nodes: children)
    }
    
    public override func children(forParent parent: MEGANode, order: Int) -> MEGANodeList {
        let children = nodes.filter { $0.parentHandle == parent.handle }
        return MockNodeList(nodes: children)
    }
    
    public override func childNode(forParent parent: MEGANode, name: String, type: MEGANodeType) -> MEGANode? {
        nodes.first(where: { $0.name == name && $0.type == type })
    }
    
    public override func childNode(forParent parent: MEGANode, name: String) -> MEGANode? {
        nodes.first(where: { $0.name == name && $0.parentHandle == parent.handle })
    }
    
    public override func contacts() -> MEGAUserList { myContacts }
    
    public override func sendEvent(_ eventType: Int, message: String, addJourneyId: Bool, viewId: String?) {
        sendEvent_Calls.append((eventType, message, addJourneyId, viewId))
    }
    
    public override func add(_ delegate: any MEGAGlobalDelegate) {
        hasGlobalDelegate = true
    }
    
    public override func add(_ delegate: MEGAGlobalDelegate, queueType: ListenerQueueType) {
        hasGlobalDelegate = true
        delegateQueueType = queueType
    }
    
    public override func remove(_ delegate: any MEGAGlobalDelegate) {
        hasGlobalDelegate = false
    }
    
    public override func add(_ delegate: any MEGARequestDelegate) {
        hasRequestDelegate = true
    }
    
    public override func remove(_ delegate: any MEGARequestDelegate) {
        hasRequestDelegate = false
    }
    
    public override func add(_ delegate: any MEGATransferDelegate) {
        hasTransferDelegate = true
    }
    
    public override func remove(_ delegate: any MEGATransferDelegate) {
        hasTransferDelegate = false
    }
    
    public override func add(_ delegate: any MEGADelegate) {
        addMEGADelegateCallCount += 1
    }
    
    public override func remove(_ delegate: any MEGADelegate) {
        removeMEGADelegateCallCount += 1
    }
    
    public override func copy(_ node: MEGANode, newParent: MEGANode) {
        copyNodeWithSameNameCallCount += 1
    }
    
    public override func copy(_ node: MEGANode, newParent: MEGANode, newName: String) {
        copyNodeWithNewNameCallCount += 1
    }
    
    public override func copy(_ node: MEGANode, newParent: MEGANode, delegate: any MEGARequestDelegate) {
        copyNodeWithSameNameCallCount += 1
        processCopyNodeWithDelegate(delegate, node: node)
    }
    
    public override func copy(_ node: MEGANode, newParent: MEGANode, newName: String, delegate: MEGARequestDelegate) {
        copyNodeWithNewNameCallCount += 1
        processCopyNodeWithDelegate(delegate, node: node)
    }
    
    private func processCopyNodeWithDelegate(_ delegate: MEGARequestDelegate, node: MEGANode) {
        let mockRequest = MockRequest(handle: copiedNodeHandles[node.handle] ?? .invalid)
        delegate.onRequestFinish?(self,
                                  request: mockRequest,
                                  error: MockError(errorType: megaSetError))
    }
    
    public override func move(_ node: MEGANode, newParent: MEGANode, delegate: MEGARequestDelegate) {
        moveNodeWithSameNameCallCount += 1
        processRequestResult(delegate: delegate)
    }
    
    public override func move(_ node: MEGANode, newParent: MEGANode, newName: String, delegate: MEGARequestDelegate) {
        moveNodeWithNewNameCallCount += 1
        processRequestResult(delegate: delegate)
    }

    public override var rootNode: MEGANode? { megaRootNode }
    public override var rubbishNode: MEGANode? { rubbishBinNode }
    
    public override func search(with filter: MEGASearchFilter, orderType: MEGASortOrderType, page: MEGASearchPage?, cancelToken: MEGACancelToken) -> MEGANodeList {
        searchQueryParameters = SearchQueryParameters(node: MockNode(handle: filter.parentNodeHandle),
                                                      searchString: filter.term,
                                                      recursive: true,
                                                      sortOrderType: orderType,
                                                      formatType: filter.category,
                                                      sensitiveFilter: filter.sensitiveFilter,
                                                      favouriteFilter: filter.favouriteFilter,
                                                      pageOffset: page?.startingOffset,
                                                      pageSize: page?.pageSize)
        searchWithFilterCallCount += 1
        return MockNodeList(nodes: nodes)
    }
    
    public override func searchNonRecursively(with filter: MEGASearchFilter, orderType: MEGASortOrderType, page: MEGASearchPage?, cancelToken: MEGACancelToken) -> MEGANodeList {
        searchQueryParameters = SearchQueryParameters(node: MockNode(handle: filter.parentNodeHandle),
                                                      searchString: filter.term,
                                                      recursive: false,
                                                      sortOrderType: orderType,
                                                      formatType: filter.category,
                                                      sensitiveFilter: filter.sensitiveFilter,
                                                      favouriteFilter: filter.favouriteFilter,
                                                      pageOffset: page?.startingOffset,
                                                      pageSize: page?.pageSize)
        
        searchNonRecursivelyWithFilterCallCount += 1
        return MockNodeList(nodes: nodes)
    }
    
    public override func nodePath(for node: MEGANode) -> String? {
        guard let mockNode = node as? MockNode else { return nil }
        
        return mockNode.nodePath
    }
    
    public override func numberChildren(forParent parent: MEGANode?) -> Int {
        var numberChildren = 0
        for node in nodes where node.parentHandle == parent?.handle {
            numberChildren += 1
        }
        return numberChildren
    }
    
    public override func isNodeInheritingSensitivity(_ node: MEGANode) -> Bool {
        _isNodeInheritingSensitivity
    }
    
    // MARK: - Sets
    
    public override func megaSets() -> [MEGASet] {
        megaSetsCallCount += 1
        return sets
    }
    
    public override func setBySid(_ sid: MEGAHandle) -> MEGASet? {
        sets.first { $0.handle == sid }
    }
    
    public override func megaSetElements(bySid sid: MEGAHandle, includeElementsInRubbishBin: Bool) -> [MEGASetElement] {
        setElements
    }
    
    public override func megaSetElementCount(_ sid: MEGAHandle, includeElementsInRubbishBin: Bool) -> UInt {
        megaSetElementCounts[sid] ?? 0
    }
    
    public override func megaSetElement(bySid sid: MEGAHandle, eid: MEGAHandle) -> MEGASetElement? {
        setElements.first(where: { $0.handle == eid})
    }
        
    public override func createSet(_ name: String?, type: MEGASetType, delegate: any MEGARequestDelegate) {
        messages.append(.createSet(name: name, type: type))
        let mockRequest = MockRequest(handle: 1, set: MockMEGASet(handle: 1, userId: 0, coverId: 1, name: name, type: type))
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }

    public override func updateSetName(_ sid: MEGAHandle, name: String, delegate: any MEGARequestDelegate) {
        messages.append(.updateSetName(sid: sid, name: name))
        let mockRequest = MockRequest(handle: 1, text: name)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func removeSet(_ sid: MEGAHandle, delegate: any MEGARequestDelegate) {
        messages.append(.removeSet(sid: sid))
        let mockRequest = MockRequest(handle: 1, parentHandle: sid)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func createSetElement(_ sid: MEGAHandle, nodeId: MEGAHandle, name: String?, delegate: any MEGARequestDelegate) {
        messages.append(.createSetElement(sid, nodeId: nodeId, name: name))
        let mockRequest = MockRequest(handle: 1)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func updateSetElement(_ sid: MEGAHandle, eid: MEGAHandle, name: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, text: name)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func updateSetElementOrder(_ sid: MEGAHandle, eid: MEGAHandle, order: Int64, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, number: order)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func removeSetElement(_ sid: MEGAHandle, eid: MEGAHandle, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, parentHandle: .invalid)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func putSetCover(_ sid: MEGAHandle, eid: MEGAHandle, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: eid)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func changeApiUrl(_ apiURL: String, disablepkp: Bool) {
        self.apiURL = apiURL
        self.disablepkp = disablepkp
    }
    
    public override func exportSet(_ sid: MEGAHandle, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, link: link)
        delegate.onRequestFinish?(self, request: mockRequest,
                                  error: MockError(errorType: megaSetError))
    }
    
    public override func publicLinkForExportedSet(bySid sid: MEGAHandle) -> String? {
        link
    }
    
    public override func disableExportSet(_ sid: MEGAHandle, delegate: any MEGARequestDelegate) {
        delegate.onRequestFinish?(self, request: MEGARequest(),
                                  error: MockError(errorType: megaSetError))
    }
    
    public override func fetchPublicSet(_ publicSetLink: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, set: sets.first, elementInSet: setElements)
        
        delegate.onRequestFinish?(self, request: mockRequest,
                                  error: MockError(errorType: megaSetError))
    }
    
    public override func previewElementNode(_ eid: MEGAHandle, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, publicNode: nodes.first)
        
        delegate.onRequestFinish?(self, request: mockRequest,
                                  error: MockError(errorType: megaSetError))
    }
    
    public override func publicSetElementsInPreview() -> [MEGASetElement] {
        setElements
    }
    
    // MARK: - Share
    public override func contact(forEmail: String?) -> MEGAUser? {
        sharedFolderOwner
    }
    
    public override func areCredentialsVerified(of: MEGAUser) -> Bool {
        isSharedFolderOwnerVerified
    }
    
    public override func publicLinks(_ order: MEGASortOrderType) -> MEGANodeList {
        nodeList
    }
    
    public override func outShares(_ order: MEGASortOrderType) -> MEGAShareList {
        shareList
    }
    
    public override func openShareDialog(_ node: MEGANode, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: node.handle)
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func upgradeSecurity(with delegate: any MEGARequestDelegate) {
        _upgradeSecurity(self, delegate)
    }
    
    private func filterNodeList(_ nodeList: MEGANodeList, by searchString: String) -> MEGANodeList {
        let nodeArray = nodeList.toNodeArray()
            .filter { $0.name?.contains(searchString) ?? false }
        
        return MockNodeList(nodes: nodeArray)
    }
    
    public override func disableExport(_ node: MEGANode, delegate: any MEGARequestDelegate) {
        nodes = nodes.compactMap { currentNode in
            if currentNode.handle == node.handle {
                return MockNode(handle: node.handle, isNodeExported: false)
            }
            return currentNode
        }
        
        let mockRequest = MockRequest(handle: 1)
        delegate.onRequestFinish?(self, request: mockRequest, error: MEGAError())
    }
    
    public override func accessLevel(for node: MEGANode) -> MEGAShareType {
        shareAccessLevel
    }
    
    public override func createSupportTicket(withMessage message: String, type: Int, delegate: any MEGARequestDelegate) {
        delegate.onRequestFinish?(self, request: MockRequest(handle: 1), error: MockError(errorType: createSupportTicketError))
    }
    
    // MARK: - Login Requests
    
    public override func isLoggedIn() -> Int { _isLoggedIn }
    
    public override func multiFactorAuthCheck(withEmail email: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, flag: true)
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    // MARK: - File System Inspection
    
    public override func incomingContactRequests() -> MEGAContactRequestList {
        _incomingContactRequests
    }
    
    public override func userAlertList() -> MEGAUserAlertList {
        _userAlertList
    }
    
    // MARK: - Account Management
    
    public override var isMasterBusinessAccount: Bool { _isMasterBusinessAccount }
    
    public override var isAchievementsEnabled: Bool { _isAchievementsEnabled }
    
    public override func getAccountDetails(with delegate: any MEGARequestDelegate) {
        _accountDetails(self, delegate)
    }
    
    public override func creditCardCancelSubscriptions(_ reason: String?, delegate: MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    public override func creditCardCancelSubscriptions(_ reason: String?, subscriptionId: String?, canContact: Bool, delegate: any MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    public override func getMiscFlags(with delegate: MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    public override func getSessionTransferURL(_ path: String, delegate: MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    // MARK: - SMS
    
    public override func smsAllowedState() -> SMSState {
        smsState
    }
    
    // MARK: - Backups
    public override func getBackupInfo(_ delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: 1, backupInfoList: backupInfoList)
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    public override func getUserAttributeType(_ type: MEGAUserAttribute, delegate: any MEGARequestDelegate) {
        let mockRequest: MockRequest? = switch type {
        case .deviceNames: .init(handle: 1, stringDict: devices)
        case .contentConsumptionPreferences: .init(handle: 1,
                                                   stringDict: contentConsumptionPreferences.mapValues { $0.base64Encoded ?? "Failed to encode to base64" })
        default: nil
        }
        
        delegate.onRequestFinish?(self, request: mockRequest ?? MockRequest(handle: 1), error: MockError(errorType: megaSetError))
    }
    
    public override func setUserAttributeType(_ type: MEGAUserAttribute, key: String, value: String, delegate: any MEGARequestDelegate) {
        switch type {
        case .contentConsumptionPreferences: 
            contentConsumptionPreferences[key] = value
        default:
            return
        }
        
        delegate.onRequestFinish?(self, request: MockRequest(handle: 1), error: MockError(errorType: setUserAttributeTypeMegaSetError(type)))
    }
    
    public override func deviceId() -> String? {
        _deviceId
    }

    public override func getThumbnailNode(_ node: MEGANode, destinationFilePath: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: node.handle, file: file)
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    public override func getPreviewNode(_ node: MEGANode, destinationFilePath: String, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: node.handle, file: file)
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    public override func stopPublicSetPreview() {
        stopPublicSetPreviewCalled += 1
    }
    
    public override func publicNode(forMegaFileLink megaFileLink: String, delegate: any MEGARequestDelegate) {
        messages.append(.publicNodeForMegaFileLink(megaFileLink))
        
        let mockRequest = MockRequest(
            handle: 1,
            publicNode: fileLinkNode
        )
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    // MARK: - A/B testing
    public override func getABTestValue(_ flag: String) -> Int {
        abTestValues[flag] ?? 0
    }
    
    // MARK: - Remote feature flag
    public override func remoteFeatureFlagValue(_ flag: String) -> Int {
        remoteFeatureFlagValues[flag] ?? 0
    }
    
    public override func authorizeNode(_ node: MEGANode) -> MEGANode? {
        authorizeNodeCalled += 1
        return node
    }
    
    public var stubbedDownloadTransfer: MockTransfer?
    
    public override func startDownloadNode(_ node: MEGANode, localPath: String, fileName: String?, appData: String?, startFirst: Bool, cancelToken: MEGACancelToken?, collisionCheck: CollisionCheck, collisionResolution: CollisionResolution, delegate: any MEGATransferDelegate) {
        delegate.onTransferFinish?(
            self,
            transfer: stubbedDownloadTransfer ?? MockTransfer(type: .download, nodeHandle: node.handle, parentHandle: node.parentHandle),
            error: MockError(errorType: .apiOk))
    }
    
    // MARK: - ADS
    
    public override func fetchAds(_ adFlags: AdsFlag, adUnits: MEGAStringList, publicHandle: MEGAHandle, delegate: any MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    public override func queryAds(_ adFlags: AdsFlag, publicHandle: MEGAHandle, delegate: any MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    // MARK: - Hidden Nodes
    
    public override func setNodeSensitive(_ node: MEGANode, sensitive: Bool, delegate: MEGARequestDelegate) {
        isNodeSensitive = sensitive
        let mockRequest = MockRequest(handle: node.handle)
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    // MARK: - Notifications
    
    public override func getNotificationsWith(_ delegate: MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    public override func getEnabledNotifications() -> MEGAIntegerList? {
        _enabledNotificationIdList
    }
    
    public override func getLastReadNotification(with delegate: MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    public override func setLastReadNotificationWithNotificationId(_ notificationId: UInt32, delegate: MEGARequestDelegate) {
        _lastReadNotificationId = Int32(notificationId)
        processRequestResult(delegate: delegate)
    }
    // MARK: - Recent Actions
    public override func getRecentActionsAsync(sinceDays days: Int, maxNodes: Int, delegate: MEGARequestDelegate) {
        getRecentActionsAsyncCalled = true
        processRequestResult(delegate: delegate)
    }
    
    // MARK: - Filesystem inspection
    public override func hasVersions(for node: MEGANode) -> Bool {
        _hasVersionsForNode
    }
    
    // MARK: - Devices
    public override func getDeviceName(_ deviceId: String?, delegate: any MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    public override func renameDevice(_ deviceId: String?, newName name: String, delegate: any MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }

    // MARK: - Contacts
    public override func outgoingContactRequests() -> MEGAContactRequestList {
        _outgoingContactRequests
    }
  
    public override func inviteContact(withEmail email: String, message: String?, action: MEGAInviteAction, delegate: MEGARequestDelegate) {
        processRequestResult(delegate: delegate)
    }
    
    public override func createFolder(withName name: String, parent: MEGANode, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(
            handle: createdFolderHandle ?? .invalid,
            parentHandle: parent.handle,
            name: name
        )
        
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    public override func size(for node: MEGANode) -> NSNumber {
        NSNumber(value: nodeSizes[node.handle] ?? 0)
    }
    
    public override func inShares() -> MEGANodeList {
        incomingNodes
    }
    
    public override func getFolderInfo(for node: MEGANode, delegate: any MEGARequestDelegate) {
        let mockRequest = MockRequest(handle: node.handle, folderInfo: folderInfo)
        delegate.onRequestFinish?(self, request: mockRequest, error: MockError(errorType: megaSetError))
    }
    
    // MARK: - Helper
    private func processRequestResult(delegate: any MEGARequestDelegate) {
        switch requestResult {
        case .success(let request):
            delegate.onRequestFinish?(self, request: request, error: MEGAError())
        case .failure(let error):
            delegate.onRequestFinish?(self, request: MockRequest(handle: 1), error: error)
        }
    }
}

extension MockSdk {
    public struct SearchQueryParameters: Equatable {
        public let node: MEGANode
        public let searchString: String?
        public let recursive: Bool
        public let sortOrderType: MEGASortOrderType
        public let formatType: MEGANodeFormatType
        public let sensitiveFilter: MEGASearchFilterSensitiveOption
        public let favouriteFilter: MEGASearchFilterFavouriteOption
        public let pageOffset: Int?
        public let pageSize: Int?
        
        public init(node: MEGANode,
                    searchString: String?,
                    recursive: Bool,
                    sortOrderType: MEGASortOrderType,
                    formatType: MEGANodeFormatType,
                    sensitiveFilter: MEGASearchFilterSensitiveOption,
                    favouriteFilter: MEGASearchFilterFavouriteOption,
                    pageOffset: Int? = nil,
                    pageSize: Int? = nil) {
            self.node = node
            self.searchString = searchString
            self.recursive = recursive
            self.sortOrderType = sortOrderType
            self.formatType = formatType
            self.sensitiveFilter = sensitiveFilter
            self.favouriteFilter = favouriteFilter
            self.pageOffset = pageOffset
            self.pageSize = pageSize
        }
    }
}

private extension MEGANodeList {
    func toNodeArray() -> [MEGANode] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap { node(at: $0) }
    }
}
