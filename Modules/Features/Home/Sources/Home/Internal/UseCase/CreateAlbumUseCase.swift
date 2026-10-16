import MEGADomain

protocol CreateAlbumUseCaseProtocol: Sendable {
    var isOverDiskQuota: Bool { get }
    func existingAlbumNames() async -> [String]
    func createAlbum(named name: String) async throws -> AlbumEntity
}

struct CreateAlbumUseCase: CreateAlbumUseCaseProtocol {
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let albumNameUseCase: any AlbumNameUseCaseProtocol
    private let albumListUseCase: any AlbumListUseCaseProtocol

    init(
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        albumNameUseCase: some AlbumNameUseCaseProtocol,
        albumListUseCase: some AlbumListUseCaseProtocol
    ) {
        self.accountStorageUseCase = accountStorageUseCase
        self.albumNameUseCase = albumNameUseCase
        self.albumListUseCase = albumListUseCase
    }

    var isOverDiskQuota: Bool {
        accountStorageUseCase.isPaywalled
    }

    func existingAlbumNames() async -> [String] {
        await albumNameUseCase.userAlbumNames()
    }

    func createAlbum(named name: String) async throws -> AlbumEntity {
        try await albumListUseCase.createUserAlbum(with: name)
    }
}
