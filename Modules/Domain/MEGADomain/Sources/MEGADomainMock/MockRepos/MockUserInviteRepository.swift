import MEGADomain

public struct MockUserInviteRepository: UserInviteRepositoryProtocol {
    public static var newRepo: MockUserInviteRepository {
        MockUserInviteRepository()
    }
    
    private let requestResult: Result<Void, InviteErrorEntity>
    
    public init(
        requestResult: Result<Void, InviteErrorEntity> = .failure(InviteErrorEntity.generic(""))
    ) {
        self.requestResult = requestResult
    }
    
    public func sendInvite(forEmail email: String) async throws {
        try requestResult.get()
    }
}
