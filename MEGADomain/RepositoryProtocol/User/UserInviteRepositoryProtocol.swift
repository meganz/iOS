

protocol UserInviteRepositoryProtocol {
    func sendInvite(forEmail email: String,
                    completion: @escaping (Result<Void, InviteError>) -> Void)
}
