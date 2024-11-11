public protocol SMSRepositoryProtocol: RepositoryProtocol, Sendable {
    func verifiedPhoneNumber() -> String?
    func getRegionCallingCodes() async throws -> [RegionEntity]
    func checkVerificationCode(_ code: String) async throws -> String
    func sendVerification(toPhoneNumber: String) async throws -> String
    func checkState() -> SMSStateEntity
}
