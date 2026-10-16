import Foundation
import MEGADomain
import MEGASdk

public struct FileFingerprintRepository: FileFingerprintRepositoryProtocol {
    public static var newRepo: FileFingerprintRepository {
        FileFingerprintRepository(sdk: .sharedSdk)
    }

    private let sdk: MEGASdk

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func fingerprint(forFileAt url: URL) -> String? {
        sdk.fingerprint(forFilePath: url.path)
    }
}
