import ChatRepo
import MEGAChatSdk

public final class MockChatRoom: MEGAChatRoom {
    private let _chatId: UInt64
    private let peerPrivilage: MEGAChatRoomPrivilege
    private let ownPrivilage: MEGAChatRoomPrivilege
    private let _isPreview: Bool
    private let _isActive: Bool
    private let _isWaitingRoom: Bool
    
    public init(
        chatId: UInt64 = 1,
        peerPrivilage: MEGAChatRoomPrivilege = .unknown,
        ownPrivilage: MEGAChatRoomPrivilege = .unknown,
        isPreview: Bool = false,
        isActive: Bool = false,
        isWaitingRoom: Bool = false
    ) {
        self._chatId = chatId
        self.peerPrivilage = peerPrivilage
        self.ownPrivilage = ownPrivilage
        self._isPreview = isPreview
        self._isActive = isActive
        self._isWaitingRoom = isWaitingRoom
        super.init()
    }
    
    public override var chatId: UInt64 {
        _chatId
    }
    
    public override var ownPrivilege: MEGAChatRoomPrivilege {
        ownPrivilage
    }
    
    public override func peerPrivilege(byHandle userHande: UInt64) -> MEGAChatRoomPrivilege {
        peerPrivilage
    }
    
    public override var isPreview: Bool {
        _isPreview
    }
    
    public override var isActive: Bool {
        _isActive
    }
    
    public override var authorizationToken: String {
        ""
    }   
    
    public override var isWaitingRoomEnabled: Bool {
        _isWaitingRoom
    }
}
