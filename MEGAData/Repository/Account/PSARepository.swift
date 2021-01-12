
struct PSARepository: PSARepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        sdk.getURLPublicServiceAnnouncement(with: MEGAGenericRequestDelegate {  request, error in
            completion(.success(
                PSAEntity(identifier: 7,
                          title: "Terms of service update",
                          description: "Our revised Terms of service, Privacy and data policy, and taken down guidence policy apply from Jan 18th January 2021",
                          imageURL: "https://eu.static.mega.co.nz/3/images/mega/psa/psa1.png",
                          positiveText: "View Terms",
                          positiveLink: "https://mega.nz/updatedterms",
                          URL: nil)
            ))
//            switch error.type {
//            case .apiOk:
//                completion(.success(
//                    PSAEntity(
//                        identifier: request.number.intValue,
//                        title: request.name,
//                        description: request.text,
//                        imageURL: request.file,
//                        positiveText: request.password,
//                        positiveLink: request.link,
//                        URL: request.email
//                    )
//                ))
//            case .apiENoent:
//                completion(.failure(PSAErrorEntity.noDataAvailable))
//            default:
//                completion(.failure(PSAErrorEntity.generic))
//            }
        })
    }
    
    func setPSA(withIdentifier identifier: Int) {
        sdk.setPSAWithIdentifier(identifier)
    }
}
