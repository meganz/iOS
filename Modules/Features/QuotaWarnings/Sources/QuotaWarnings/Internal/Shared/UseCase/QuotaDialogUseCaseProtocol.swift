import MEGADomain

protocol QuotaDialogUseCaseProtocol: Sendable {
    /// Email of the signed-in user, pre-filled into the custom-plan support request.
    var userEmail: String? { get }

    func upgradeOption() async throws -> QuotaUpgradeOption
}
