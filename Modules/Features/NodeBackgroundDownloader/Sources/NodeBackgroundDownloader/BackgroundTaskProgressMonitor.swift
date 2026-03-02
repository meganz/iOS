import AsyncAlgorithms
import MEGADomain
import MEGASwift

protocol BackgroundTaskProgressMonitorProtocol: Sendable {
    var allCompleted: Bool { get }
    func stop()
    func start(node: NodeEntity)
    func start(onTotal: @escaping @Sendable (Int64) -> Void, onCompleted: @Sendable @escaping (Int64) -> Void) async
}

struct BackgroundTaskProgressMonitor: BackgroundTaskProgressMonitorProtocol {
    private let nodeDownloadUpdates: any NodeDownloadUpdatesUseCaseProtocol
    private let tasks: Atomic<[Task<Void, Never>]> = Atomic(wrappedValue: [])
    private let channel = AsyncChannel<Void>()
    private let totalBytes: Atomic<Int64> = Atomic(wrappedValue: 0)
    private let transferredBytesMap: Atomic<[HandleEntity: Int64]> = Atomic(wrappedValue: [:])
    private var transferredBytes: Int64 { transferredBytesMap.wrappedValue.values.reduce(0, +) }
    private var _pendingDownloads: Atomic<Int> = Atomic(wrappedValue: 0)
    private var _totalDownloads: Atomic<Int> = Atomic(wrappedValue: 0)
    
    var totalDownloads: Int {
        _totalDownloads.wrappedValue
    }
    
    var pendingDownloads: Int {
        _pendingDownloads.wrappedValue
    }
    
    var completedDownloads: Int {
        totalDownloads - pendingDownloads
    }
    
    var allCompleted: Bool {
        pendingDownloads == 0
    }
    
    init(nodeDownloadUpdates: some NodeDownloadUpdatesUseCaseProtocol) {
        self.nodeDownloadUpdates = nodeDownloadUpdates
    }
    
    func start(node: NodeEntity) {
        let task = Task {
            for await progressUpdates in nodeDownloadUpdates.startMonitoringDownloadProgress(for: node) {
                if Task.isCancelled {
                    break
                }
                switch progressUpdates {
                case let .start(progress):
                    totalBytes.mutate({ $0 += progress })
                    _pendingDownloads.mutate({ $0 += 1 })
                    _totalDownloads.mutate({ $0 += 1 })
                case let .update(progress):
                    transferredBytesMap.mutate({ $0[node.handle] = progress })
                case let .finish(progress):
                    transferredBytesMap.mutate({ $0[node.handle] = progress })
                    _pendingDownloads.mutate({ $0 -= 1 })
                }
                await channel.send(())
                if _pendingDownloads.wrappedValue == 0 {
                    channel.finish()
                }
            }
        }
        tasks.mutate({ $0.append(task) })
    }
    
    func start(onTotal: @escaping @Sendable (Int64) -> Void, onCompleted: @Sendable @escaping (Int64) -> Void) async {
        for await _ in channel {
            if Task.isCancelled {
                break
            }
            onTotal(totalBytes.wrappedValue)
            onCompleted(transferredBytes)
        }
        stop()
    }
    
    func stop() {
        _pendingDownloads.mutate({ $0 = 0 })
        tasks.mutate {
            for task in $0 {
                task.cancel()
            }
            $0 = []
        }
        channel.finish()
    }
}
