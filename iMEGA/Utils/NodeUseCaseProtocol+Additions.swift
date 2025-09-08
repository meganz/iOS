import MEGADomain

public extension NodeUseCaseProtocol {
    func isNodeDecryptedNonThrowing(node: NodeEntity, fromFolderLink: Bool = false) -> Bool {
        (try? isNodeDecrypted(node: node, fromFolderLink: fromFolderLink) == true) ?? false
    }
}
