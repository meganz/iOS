import MEGADomain

/// `CallsManagerProtocol` defines how active and ongoing calls are managed.
/// It provides methods to handle the lifecycle of calls, associate them with unique identifiers, and update their state.
/// The implementation of this protocol is responsible for maintaining the state of calls in memory and ensuring consistency during call-related operations.
protocol CallsManagerProtocol {
    func callUUID(forChatRoom chatRoom: ChatRoomEntity) -> UUID?
    func call(forUUID uuid: UUID) -> CallActionSync?
    func removeCall(withUUID uuid: UUID)
    func removeAllCalls()
    func updateCall(withUUID uuid: UUID, muted: Bool)
    func updateEndForAllCall(withUUID uuid: UUID)
    func addCall(_ call: CallActionSync, withUUID uuid: UUID)
}
