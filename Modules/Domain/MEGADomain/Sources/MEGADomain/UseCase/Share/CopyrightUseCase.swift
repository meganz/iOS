import Foundation

public protocol CopyrightUseCaseProtocol: Sendable {
    /// Determine if copyright should be approved
    ///
    /// Copyright could have been accepted from other platform or from previous install
    func shouldAutoApprove() async -> Bool
}

public struct CopyrightUseCase<S: ShareUseCaseProtocol>: CopyrightUseCaseProtocol {
    private let shareUseCase: S
    
    public init(shareUseCase: S) {
        self.shareUseCase = shareUseCase
    }
    
    public func shouldAutoApprove() async -> Bool {
        if shareUseCase.allPublicLinks(sortBy: .none).isNotEmpty {
            return true
        }
        return await shareUseCase.isAnyCollectionShared()
    }
}
