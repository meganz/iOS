import Foundation
import MEGADomain

protocol NodeInfoUseCaseProtocol: Sendable {
    func node(for handle: HandleEntity) -> MEGANode?
    func fetchAudioTracks(from folder: HandleEntity) -> [TrackEntity]?
    /// The tracks in a folder that can play with no connection — only the nodes with a local copy.
    func fetchOfflineAudioTracks(from folder: HandleEntity) -> [TrackEntity]?
    /// The tracks among `nodes` that can play with no connection — only the ones with a local copy.
    func offlineAudioTracks(from nodes: [MEGANode]) -> [TrackEntity]
    func fetchFolderLinkAudioTracks(from folder: HandleEntity) -> [TrackEntity]?
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
    
    func fetchAudioTracks(from folder: HandleEntity) -> [TrackEntity]? {
        nodeInfoRepository.fetchAudioTracks(from: folder)
    }
    
    func fetchOfflineAudioTracks(from folder: HandleEntity) -> [TrackEntity]? {
        nodeInfoRepository.fetchOfflineAudioTracks(from: folder)
    }
    
    func offlineAudioTracks(from nodes: [MEGANode]) -> [TrackEntity] {
        nodeInfoRepository.offlineAudioTracks(from: nodes)
    }
    
    func fetchFolderLinkAudioTracks(from folder: HandleEntity) -> [TrackEntity]? {
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
