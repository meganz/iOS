@testable import MEGA
import MEGADomain

final class MockNodeInfoUseCase: NodeInfoUseCaseProtocol, @unchecked Sendable {
    private var isTakenDownNode: Bool
    private let nodeForHandle: [HandleEntity: MEGANode]
    private let audioTracksInFolder: [HandleEntity: [TrackEntity]]
    private let offlineAudioTracksInFolder: [HandleEntity: [TrackEntity]]
    /// The local copy each node has, keyed by handle. A node absent from here has none, so it never
    /// reaches an offline queue.
    private let offlineTrackForHandle: [HandleEntity: TrackEntity]
    private(set) var folderLinkLogout_callTimes = 0
    private(set) var isTakenDown_callTimes = 0
    private(set) var offlineQueue_callTimes = 0

    init(
        isTakenDownNode: Bool = false,
        nodeForHandle: [HandleEntity: MEGANode] = [:],
        audioTracksInFolder: [HandleEntity: [TrackEntity]] = [:],
        offlineAudioTracksInFolder: [HandleEntity: [TrackEntity]] = [:],
        offlineTrackForHandle: [HandleEntity: TrackEntity] = [:]
    ) {
        self.isTakenDownNode = isTakenDownNode
        self.nodeForHandle = nodeForHandle
        self.audioTracksInFolder = audioTracksInFolder
        self.offlineAudioTracksInFolder = offlineAudioTracksInFolder
        self.offlineTrackForHandle = offlineTrackForHandle
    }

    func node(for handle: HandleEntity) -> MEGANode? {
        nodeForHandle[handle]
    }

    func fetchAudioTracks(from folder: HandleEntity) -> [TrackEntity]? {
        audioTracksInFolder[folder]
    }

    func fetchOfflineAudioTracks(from folder: HandleEntity) -> [TrackEntity]? {
        offlineQueue_callTimes += 1
        return offlineAudioTracksInFolder[folder]
    }

    func offlineAudioTracks(from nodes: [MEGANode]) -> [TrackEntity] {
        offlineQueue_callTimes += 1
        return nodes.compactMap { offlineTrackForHandle[$0.handle] }
    }

    func fetchFolderLinkAudioTracks(from folder: HandleEntity) -> [TrackEntity]? {
        nil
    }

    func folderLinkLogout() {
        folderLinkLogout_callTimes += 1
    }

    func isTakenDown(node: MEGANode, isFolderLink: Bool) async throws -> Bool {
        isTakenDown_callTimes += 1
        return isTakenDownNode
    }
}
