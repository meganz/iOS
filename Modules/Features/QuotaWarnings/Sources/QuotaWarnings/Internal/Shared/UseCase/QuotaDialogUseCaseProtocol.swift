import MEGADomain

protocol QuotaDialogUseCaseProtocol: Sendable {
    func upgradeOption() async throws -> QuotaUpgradeOption
}
