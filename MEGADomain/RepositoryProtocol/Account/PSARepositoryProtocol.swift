
protocol PSARepositoryProtocol {
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void)
    func setPSA(withIdentifier identifier: PSAIdentifier)
}
