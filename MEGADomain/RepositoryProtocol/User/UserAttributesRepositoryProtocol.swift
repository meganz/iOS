
protocol UserAttributesRepositoryProtocol {
    func loadUserAttributes(in chatId: MEGAHandle, for userHandles: [NSNumber], completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
}
