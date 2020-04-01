import MessageKit

extension MEGAUser: SenderType {
    public var senderId: String {
        return String(format: "%llu", handle)
    }
    
    public var displayName: String {
        return String(format: "%llu", handle)
    }
}



