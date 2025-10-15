import Foundation
import MEGADomain
import MEGASwift

public actor CameraUploadTransferProgressRepository: CameraUploadTransferProgressRepositoryProtocol {
    private typealias LocalIdentifier = String
    private typealias TaskIdentifier = Int
    private typealias ChunkIndex = Int
    private typealias ByteCount = Int64
    
    private struct TaskInfo: Sendable, Hashable {
        let localIdentifier: String
        let chunkIndex: Int
    }
    
    public static let shared = CameraUploadTransferProgressRepository()
    
    public private(set) var activeUploads = [CameraUploadLocalIdentifierEntity]()
    private var taskMap: [TaskIdentifier: TaskInfo] = [:]
    private var sentByChunk: [LocalIdentifier: [ChunkIndex: ByteCount]] = [:]
    private var sentByFile: [LocalIdentifier: ByteCount] = [:]
    private var expectedByChunk: [LocalIdentifier: [ChunkIndex: ByteCount]] = [:]
    private var totalExpectedByFile: [LocalIdentifier: ByteCount] = [:]
    private var speedSamples: [LocalIdentifier: [CameraUploadTaskProgressRawDataEntity.SpeedSample]] = [:]
    private var progressContinuations: [LocalIdentifier: AsyncStream<CameraUploadTaskProgressRawDataEntity>.Continuation] = [:]
    private var cameraUploadPhaseContinuations: [UUID: AsyncStream<CameraUploadPhaseEventEntity>.Continuation] = [:]
    private var pruneSpeedMeasurementsWindowSize: TimeInterval
    
    init(pruneSpeedMeasurementsWindowSize: TimeInterval = 5.0) {
        self.pruneSpeedMeasurementsWindowSize = pruneSpeedMeasurementsWindowSize
    }
    
    public var cameraUploadPhaseEventUpdates: AnyAsyncSequence<CameraUploadPhaseEventEntity> {
        let (stream, continuation) = AsyncStream
            .makeStream(of: CameraUploadPhaseEventEntity.self)
        let id = UUID()
        cameraUploadPhaseContinuations[id] = continuation
        continuation.onTermination = { @Sendable [weak self, id] _ in
            Task { [weak self] in await self?.terminateContinuation(id: id) }
        }
        return stream.eraseToAnyAsyncSequence()
    }
    
    public func registerTask(identifier: Int, info: CameraUploadTaskInfoEntity, totalBytesExpectedToWrite: Int64) {
        let localIdentifier = info.localIdentifier
        let taskInfo = TaskInfo(localIdentifier: localIdentifier, chunkIndex: info.chunkIndex)
        taskMap[identifier] = taskInfo
        
        initDataStorageIfNeeded(for: localIdentifier)
        sentByFile[info.localIdentifier] = 0
        updateTotalExpected(for: info, totalBytesExpected: totalBytesExpectedToWrite)
        addSpeedSample(for: info.localIdentifier, bytesSent: 0)
        
        addToActiveUploads(info.localIdentifier)
        
        emitProgressUpdate(for: taskInfo.localIdentifier)
    }
    
    public func updateTaskProgress(identifier: Int, info: CameraUploadTaskInfoEntity, totalBytesSent: Int64, totalBytesExpected: Int64) {
        let localIdentifier = info.localIdentifier
        let isFirstBytesSent = (sentByFile[localIdentifier] ?? 0) == 0
        
        updateTotalSent(for: info, totalBytesSent: totalBytesSent)
        updateTotalExpected(for: info, totalBytesExpected: totalBytesExpected)
        
        let totalBytes = totalSent(for: localIdentifier)
        addSpeedSample(for: localIdentifier, bytesSent: totalBytes)
        
        if isFirstBytesSent && totalBytesSent > 0 {
            emitPhaseEvent(for: localIdentifier, phase: .uploading)
        }
        emitProgressUpdate(for: localIdentifier)
    }
    
    public func completeTask(identifier: Int, info: CameraUploadTaskInfoEntity) {
        let localIdentifier = info.localIdentifier
        
        taskMap.removeValue(forKey: identifier)
        
        guard taskMap.values.notContains(where: { $0.localIdentifier == localIdentifier }) else { return }
        
        emitProgressUpdate(for: localIdentifier)
        
        sentByFile.removeValue(forKey: localIdentifier)
        expectedByChunk.removeValue(forKey: localIdentifier)
        totalExpectedByFile.removeValue(forKey: localIdentifier)
        
        progressContinuations[localIdentifier]?.finish()
        progressContinuations.removeValue(forKey: localIdentifier)
        
        activeUploads.remove(object: localIdentifier)
        emitPhaseEvent(for: localIdentifier, phase: .completed)
    }
    
    public func restoreTasks(for localIdentifier: CameraUploadLocalIdentifierEntity, taskIdentifierForChunk: [Int: Int], totalBytesSent: Int64, expectedBytesPerChunk: [Int: Int64]) {
        for (taskId, taskInfo) in taskMap where taskInfo.localIdentifier == localIdentifier {
            taskMap.removeValue(forKey: taskId)
        }
        for (taskId, chunkId) in taskIdentifierForChunk {
            taskMap[taskId] = TaskInfo(localIdentifier: localIdentifier, chunkIndex: chunkId)
        }
        
        initDataStorageIfNeeded(for: localIdentifier)
        sentByFile[localIdentifier] = totalBytesSent
        expectedByChunk[localIdentifier] = expectedBytesPerChunk
        totalExpectedByFile[localIdentifier] = expectedBytesPerChunk.values.reduce(0, +)
        
        let totalBytes = totalSent(for: localIdentifier)
        addSpeedSample(for: localIdentifier, bytesSent: totalBytes)
        
        addToActiveUploads(localIdentifier)
        
        emitProgressUpdate(for: localIdentifier)
    }
    
    public func progressRawData(for localIdentifier: String) -> CameraUploadTaskProgressRawDataEntity {
        .init(
            totalBytesSent: totalSent(for: localIdentifier),
            totalBytesExpected: totalExpectedByFile[localIdentifier] ?? 0,
            speedSamples: speedSamples[localIdentifier] ?? []
        )
    }
    
    public func progressRawDataUpdates(for localIdentifier: String) -> AnyAsyncSequence<CameraUploadTaskProgressRawDataEntity> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: CameraUploadTaskProgressRawDataEntity.self,
            bufferingPolicy: .bufferingNewest(1))
        progressContinuations[localIdentifier]?.finish()
        progressContinuations[localIdentifier] = continuation
        return stream.eraseToAnyAsyncSequence()
    }
    
    private func totalSent(for localIdentifier: LocalIdentifier) -> Int64 {
        sentByFile[localIdentifier] ?? 0
    }
    
    private func initDataStorageIfNeeded(for localIdentifier: LocalIdentifier) {
        if sentByFile[localIdentifier] == nil {
            sentByFile[localIdentifier] = 0
        }
        if expectedByChunk[localIdentifier] == nil {
            expectedByChunk[localIdentifier] = [:]
        }
        if speedSamples[localIdentifier] == nil {
            speedSamples[localIdentifier] = []
        }
    }
    
    private func addToActiveUploads(_ localIdentifier: String) {
        guard activeUploads.notContains(localIdentifier) else { return }
        
        activeUploads.append(localIdentifier)
        emitPhaseEvent(for: localIdentifier, phase: .registered)
    }
    
    private func emitProgressUpdate(for localIdentifier: LocalIdentifier) {
        guard let continuation = progressContinuations[localIdentifier] else { return }
        
        let progress = progressRawData(for: localIdentifier)
        
        continuation.yield(progress)
    }
    
    private func terminateContinuation(id: UUID) {
        cameraUploadPhaseContinuations[id] = nil
    }
    
    private func emitPhaseEvent(
        for assetIdentifier: CameraUploadLocalIdentifierEntity,
        phase: CameraUploadPhaseEventEntity.Phase
    ) {
        guard cameraUploadPhaseContinuations.isNotEmpty else { return }
        emitPhaseEventToContinuations(phaseEvent: .init(
            assetIdentifier: assetIdentifier,
            phase: phase))
    }
    
    private func emitPhaseEventToContinuations(phaseEvent: CameraUploadPhaseEventEntity) {
        for continuation in cameraUploadPhaseContinuations.values {
            continuation.yield(phaseEvent)
        }
    }
    
    private func addSpeedSample(for localIdentifier: LocalIdentifier, bytesSent: Int64) {
        let sample = CameraUploadTaskProgressRawDataEntity
            .SpeedSample(timestamp: Date(), bytesSent: bytesSent)
        speedSamples[localIdentifier]?.append(sample)
        
        pruneOldSpeedSamples(for: localIdentifier)
    }
    
    private func pruneOldSpeedSamples(for localIdentifier: LocalIdentifier) {
        guard speedSamples.isNotEmpty else { return }
        
        let cutoffTime = Date().addingTimeInterval(-pruneSpeedMeasurementsWindowSize)
        
        speedSamples[localIdentifier] = speedSamples[localIdentifier]?.filter {
            $0.timestamp >= cutoffTime
        }
    }
    
    private func updateTotalSent(for info: CameraUploadTaskInfoEntity, totalBytesSent: Int64) {
        let localIdentifier = info.localIdentifier
        let chunkIndex = info.chunkIndex
        var sentPerChunk = sentByChunk[localIdentifier] ?? [:]
        let previousChunkSent = sentPerChunk[chunkIndex] ?? 0
        let currentTotalSent = sentByFile[localIdentifier] ?? 0
        
        let chunkDelta = max(0, totalBytesSent - previousChunkSent)
        let newTotalSent = currentTotalSent + chunkDelta
        
        sentPerChunk[chunkIndex] = totalBytesSent
        sentByChunk[localIdentifier] = sentPerChunk
        sentByFile[localIdentifier] = newTotalSent
    }
    
    private func updateTotalExpected(for info: CameraUploadTaskInfoEntity, totalBytesExpected: Int64) {
        var perChunk = expectedByChunk[info.localIdentifier] ?? [:]
        let previousValue = perChunk[info.chunkIndex]
        
        perChunk[info.chunkIndex] = totalBytesExpected
        expectedByChunk[info.localIdentifier] = perChunk
        
        if previousValue != totalBytesExpected {
            totalExpectedByFile[info.localIdentifier] = perChunk.values.reduce(0, +)
        }
    }
}
