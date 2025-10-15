import Foundation

protocol OfflineFileInfoUseCaseProtocol: Sendable {
    @MainActor
    func fetchTracks(from files: [String]?) -> [AudioPlayerItem]?
}

final class OfflineFileInfoUseCase: OfflineFileInfoUseCaseProtocol {
    private let offlineInfoRepository: any OfflineInfoRepositoryProtocol
    
    init(offlineInfoRepository: some OfflineInfoRepositoryProtocol = OfflineInfoRepository()) {
        self.offlineInfoRepository = offlineInfoRepository
    }
    
    @MainActor
    func fetchTracks(from files: [String]?) -> [AudioPlayerItem]? {
        offlineInfoRepository.fetchTracks(from: files)
    }
}
