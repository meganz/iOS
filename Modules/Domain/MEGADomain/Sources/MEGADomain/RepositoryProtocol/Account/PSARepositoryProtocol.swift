
public protocol PSARepositoryProtocol: RepositoryProtocol {
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void)
    func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier)
}
