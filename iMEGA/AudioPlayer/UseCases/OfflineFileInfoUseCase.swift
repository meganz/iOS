import Foundation

protocol OfflineFileInfoUseCaseProtocol: Sendable {
    func fetchTracks(from files: [String]?) -> [AudioPlayerItem]?
}

final class OfflineFileInfoUseCase: OfflineFileInfoUseCaseProtocol {
    private let offlineInfoRepository: any OfflineInfoRepositoryProtocol
    
    init(offlineInfoRepository: some OfflineInfoRepositoryProtocol = OfflineInfoRepository()) {
        self.offlineInfoRepository = offlineInfoRepository
    }
    
    func fetchTracks(from files: [String]?) -> [AudioPlayerItem]? {
        offlineInfoRepository.fetchTracks(from: files)
    }
}
