import MEGASwift

public protocol ChatRoomUpdateRepositoryProtocol: Sendable {
    /// - Returns: `AnyAsyncSequence` that will yield `ChatRoomEntity` items until sequence terminated.
    var chatRoomUpdate: AnyAsyncSequence<ChatRoomEntity> { get }
}
