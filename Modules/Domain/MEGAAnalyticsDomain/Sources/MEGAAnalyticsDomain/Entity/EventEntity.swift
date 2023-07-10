public typealias EventID = Int
public typealias ViewID = String

public struct EventEntity: Equatable {
    public let id: EventID
    public let message: String
    public let viewId: ViewID?
    
    public init(id: EventID, message: String, viewId: ViewID? = nil) {
        self.id = id
        self.message = message
        self.viewId = viewId
    }
}
