import Foundation

public protocol CopyrightUseCaseProtocol: Sendable {
    /// Determine if copyright should be approved
    ///
    /// Copyright could have been accepted from other platform or from previous install
    func shouldAutoApprove() async -> Bool
}

public struct CopyrightUseCase<S: ShareUseCaseProtocol,
                               U: UserAlbumRepositoryProtocol>: CopyrightUseCaseProtocol {
    private let shareUseCase: S
    private let userAlbumRepository: U
    
    public init(shareUseCase: S,
                userAlbumRepository: U) {
        self.shareUseCase = shareUseCase
        self.userAlbumRepository = userAlbumRepository
    }
    
    public func shouldAutoApprove() async -> Bool {
        if shareUseCase.allPublicLinks(sortBy: .none).isNotEmpty {
            return true
        }
        return await userAlbumRepository.albums()
            .contains(where: { $0.isExported })
    }
}
