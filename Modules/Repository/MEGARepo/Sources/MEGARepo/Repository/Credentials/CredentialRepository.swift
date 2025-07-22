import Foundation
import MEGADomain
import SAMKeychain

public struct CredentialRepository: CredentialRepositoryProtocol {
    public static var newRepo: CredentialRepository {
        CredentialRepository()
    }
    
    private enum Constants {
        static let keychainServiceName = "MEGA"
        static let keychainSessionAccountName = "sessionV3"
        static let keychainSessionIdAccountName = "sessionId"
        static let keychainEmailAccountName = "email"
        static let keychainNameAccountName = "name"
        static let keychainPasswordAccountName = "password"
        static let keychainPasscodeServiceName = "demoServiceName"
        static let keychainPasscodeAccountName = "demoPasscode"
    }
    
    public func sessionId() -> String? {
        SAMKeychain.password(forService: Constants.keychainServiceName, account: Constants.keychainSessionAccountName)
    }
    
    public func clearSession() {
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainSessionAccountName)
    }
    
    public func clearEphemeralSession() {
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainSessionIdAccountName)
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainEmailAccountName)
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainNameAccountName)
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName,
                                   account: Constants.keychainPasswordAccountName)
    }
    
    public func isPasscodeEnabled() -> Bool {
        SAMKeychain.password(forService: Constants.keychainPasscodeServiceName, account: Constants.keychainPasscodeAccountName) != nil
    }
}
