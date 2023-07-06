public struct AccountPlanErrorEntity {
    public let errorCode: Int
    public let errorMessage: String?
    
    public init(errorCode: Int, errorMessage: String?) {
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }
}
