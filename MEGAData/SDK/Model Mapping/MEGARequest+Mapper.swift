import MEGADomain

extension MEGARequest {
    func toPSAEntity() -> PSAEntity {
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
    
    func toFileURL() -> URL? {
        guard let path = file else {
            return nil
        }
        
        return URL(string: path)
    }
    
    func toMEGANode(in sdk: MEGASdk) -> MEGANode? {
        sdk.node(forHandle: nodeHandle)
    }
    
    func toNodeEntity(in sdk: MEGASdk) -> NodeEntity? {
        toMEGANode(in: sdk)?.toNodeEntity()
    }
}
