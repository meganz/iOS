import MEGADomain

public extension NodeUseCaseProtocol {
    func isNodeDecryptedNonThrowing(node: NodeEntity) -> Bool {
        (try? isNodeDecrypted(node: node) == true) ?? false
    }
}
