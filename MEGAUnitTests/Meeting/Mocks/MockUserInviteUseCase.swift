@testable import MEGA

struct MockUserInviteUseCase: UserInviteUseCaseProtocol {
    var result: Result<Void, InviteErrorEntity> = .failure(.generic(""))
    func sendInvite(forEmail email: String,
                    completion: @escaping (Result<Void, InviteErrorEntity>) -> Void) {
        completion(result)
    }
}
