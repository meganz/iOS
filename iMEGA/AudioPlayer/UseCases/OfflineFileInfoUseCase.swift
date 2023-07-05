import Foundation

protocol OfflineFileInfoUseCaseProtocol {
    func info(from files: [String]?) -> [AudioPlayerItem]?
}

final class OfflineFileInfoUseCase: OfflineFileInfoUseCaseProtocol {
    
    private var offlineInfoRepository: any OfflineInfoRepositoryProtocol
    
    init(offlineInfoRepository: some OfflineInfoRepositoryProtocol = OfflineInfoRepository()) {
        self.offlineInfoRepository = offlineInfoRepository
    }
    
    func info(from files: [String]?) -> [AudioPlayerItem]? {
        offlineInfoRepository.info(fromFiles: files)
    }
}
