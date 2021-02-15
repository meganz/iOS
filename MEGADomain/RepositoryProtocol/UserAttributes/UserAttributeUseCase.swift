
protocol UserAttributesUseCaseProtocol {
    func getUserAttributes(in chatId: MEGAHandle, for userHandle: NSNumber, completion: @escaping (Result<MEGAChatRoom, CallsErrorEntity>) -> Void)
}

final class UserAttributesUseCase: UserAttributesUseCaseProtocol {
    
    private let repository: UserAttributesRepositoryProtocol

    init(repository: UserAttributesRepositoryProtocol) {
        self.repository = repository
    }
    
    func getUserAttributes(in chatId: MEGAHandle, for userHandle: NSNumber, completion: @escaping (Result<MEGAChatRoom, CallsErrorEntity>) -> Void) {
        repository.loadUserAttributes(in: chatId, for: [userHandle], completion: completion)
    }
}
