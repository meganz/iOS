
public protocol SMSRepositoryProtocol: RepositoryProtocol {
    func verifiedPhoneNumber() -> String?
    func getRegionCallingCodes(completion: @escaping (Result<[RegionEntity], GetSMSErrorEntity>) -> Void)
    func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void)
    func sendVerification(toPhoneNumber: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void)
    func checkState() -> SMSStateEntity
}
