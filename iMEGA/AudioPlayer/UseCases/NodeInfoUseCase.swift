import Foundation
import MEGADomain

protocol NodeInfoUseCaseProtocol: Sendable {
    func node(for handle: HandleEntity) -> MEGANode?
    func fetchAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]?
    func fetchFolderLinkAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]?
    func folderLinkLogout()
    func isTakenDown(node: MEGANode, isFolderLink: Bool) async throws -> Bool
}

final class NodeInfoUseCase: NodeInfoUseCaseProtocol {
    private let nodeInfoRepository: any NodeInfoRepositoryProtocol
    
    init(nodeInfoRepository: some NodeInfoRepositoryProtocol = NodeInfoRepository()) {
        self.nodeInfoRepository = nodeInfoRepository
    }
    
    func node(for handle: HandleEntity) -> MEGANode? {
        nodeInfoRepository.node(for: handle)
    }
    
    func fetchAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]? {
        nodeInfoRepository.fetchAudioTracks(from: folder)
    }
    
    func fetchFolderLinkAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]? {
        nodeInfoRepository.fetchFolderLinkAudioTracks(from: folder)
    }
    
    func folderLinkLogout() {
        nodeInfoRepository.folderLinkLogout()
    }
    
    func isTakenDown(node: MEGANode, isFolderLink: Bool) async throws -> Bool {
        guard isFolderLink else {
            return try await nodeInfoRepository.isNodeTakenDown(node: node)
        }
        return try await nodeInfoRepository.isFolderLinkNodeTakenDown(node: node)
    }
}
