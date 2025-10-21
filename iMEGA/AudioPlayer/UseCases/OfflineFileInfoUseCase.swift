import Foundation

protocol OfflineFileInfoUseCaseProtocol: Sendable {
    func fetchTracks(from files: [String]?) -> [TrackEntity]?
}

final class OfflineFileInfoUseCase: OfflineFileInfoUseCaseProtocol {
    private let offlineInfoRepository: any OfflineInfoRepositoryProtocol
    
    init(offlineInfoRepository: some OfflineInfoRepositoryProtocol = OfflineInfoRepository()) {
        self.offlineInfoRepository = offlineInfoRepository
    }
    
    func fetchTracks(from files: [String]?) -> [TrackEntity]? {
        offlineInfoRepository.fetchTracks(from: files)
    }
}
