@testable import MEGA

struct MockUserInviteUseCase: UserInviteUseCaseProtocol {
    var result: Result<Void, InviteError> = .failure(.generic(""))
    func sendInvite(forEmail email: String,
                    completion: @escaping (Result<Void, InviteError>) -> Void) {
        completion(result)
    }
}
