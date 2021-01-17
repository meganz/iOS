
struct PSARepository: PSARepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        sdk.getURLPublicServiceAnnouncement(with: MEGAGenericRequestDelegate {  request, error in
            switch error.type {
            case .apiOk:
                completion(.success(
                    PSAEntity(
                        identifier: request.number.intValue,
                        title: request.name,
                        description: request.text,
                        imageURL: request.file,
                        positiveText: request.password,
                        positiveLink: request.link,
                        URLString: request.email
                    )
                ))
            case .apiENoent:
                completion(.failure(PSAErrorEntity.noDataAvailable))
            default:
                completion(.failure(PSAErrorEntity.generic))
            }
        })
    }
    
    func setPSA(withIdentifier identifier: Int) {
        sdk.setPSAWithIdentifier(identifier)
    }
}
