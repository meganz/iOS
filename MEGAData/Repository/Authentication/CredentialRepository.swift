import Foundation
import SAMKeychain

extension CredentialRepository {
    static let `default` = CredentialRepository()
}

struct CredentialRepository: CredentialRepositoryProtocol {
    private enum Constants {
        static let keychainServiceName = "MEGA"
        static let keychainSessionAccountName = "sessionV3"
        static let keychainSessionIdAccountName = "sessionId"
        static let keychainEmailAccountName = "email"
        static let keychainNameAccountName = "name"
        static let keychainPasswordAccountName = "password"
    }
    
    func sessionId(service: String, account: String) -> String? {
        SAMKeychain.password(forService: service, account: account)
    }
    
    func clearSession() {
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainSessionAccountName)
    }
    
    func clearEphemeralSession() {
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainSessionIdAccountName)
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainEmailAccountName)
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainNameAccountName)
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainPasswordAccountName)
    }
}
