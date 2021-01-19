@testable import MEGA

struct MockPSARepository: PSARepositoryProtocol {
    enum MockOption {
        case successPSAEntity
        case successURLPSAEntity
        case genericError
        case noDataAvailable
    }
    
    let mockOption: MockOption
    
    
    func getPSA(completion: @escaping (Result<PSAEntity, PSAErrorEntity>) -> Void) {
        switch mockOption {
        case .successPSAEntity:
            completion(.success(PSAEntity.mocPSAEntity()))
        case .successURLPSAEntity:
            completion(.success(PSAEntity.mocURLPSAEntity()))
        case .genericError:
            completion(.failure(PSAErrorEntity.generic))
        case .noDataAvailable:
            completion(.failure(PSAErrorEntity.noDataAvailable))
        }
    }
    
    func setPSA(withIdentifier identifier: Int) { }
}

final class MockPSAViewRouterDelegate: PSAViewRouterDelegate {
    func psaViewdismissed() {}
}

extension PSAEntity {
    static func mocPSAEntity() -> PSAEntity {
        return PSAEntity(identifier: 400,
                         title: "Terms of service update",
                         description: "Our revised Terms of service, Privacy and data policy, and taken down guidence policy apply from Jan 18th January 2021",
                         imageURL: "https://eu.static.mega.co.nz/3/images/mega/psa/psa1.png",
                         positiveText: "View Terms",
                         positiveLink: "https://mega.nz/updatedterms",
                         URLString: nil
        )
    }
    
    static func mocURLPSAEntity() -> PSAEntity {
        return PSAEntity(identifier: 400,
                         title: "Terms of service update",
                         description: "Our revised Terms of service, Privacy and data policy, and taken down guidence policy apply from Jan 18th January 2021",
                         imageURL: "https://eu.static.mega.co.nz/3/images/mega/psa/psa1.png",
                         positiveText: "View Terms",
                         positiveLink: "https://mega.nz/updatedterms",
                         URLString: "https://mega.nz/updatedterms"
        )
    }
}
