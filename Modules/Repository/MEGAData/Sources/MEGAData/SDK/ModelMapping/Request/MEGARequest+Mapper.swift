import MEGADomain
import MEGASdk

extension MEGARequest {
    public func toPSAEntity() -> PSAEntity {
        PSAEntity(
            identifier: number.intValue,
            title: name,
            description: text,
            imageURL: file,
            positiveText: password,
            positiveLink: link,
            URLString: email
        )
    }
    
    public func toAccountRequestEntity() -> AccountRequestEntity {
        AccountRequestEntity(
            type: type.toRequestTypeEntity(),
            file: file,
            userAttribute: UserAttributeEntity(rawValue: paramType),
            email: email,
            accountDetails: megaAccountDetails?.toAccountDetailsEntity()
        )
    }
    
    public func toFileURL() -> URL? {
        guard let path = file else {
            return nil
        }
        
        return URL(string: path)
    }
    
    public func toMEGANode(in sdk: MEGASdk) -> MEGANode? {
        sdk.node(forHandle: nodeHandle)
    }
    
    public func toNodeEntity(in sdk: MEGASdk) -> NodeEntity? {
        toMEGANode(in: sdk)?.toNodeEntity()
    }
}
