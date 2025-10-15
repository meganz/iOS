import MEGADomain
@testable import MEGARepo
import MEGASwift
import Testing

struct CameraUploadTransferProgressRepositoryTests {
    
    private let taskInfo = CameraUploadTaskInfoEntity(
        localIdentifier: "identifier",
        chunkIndex: 0,
        totalChunks: 1)
    
    @Test("registration should set correct initial value")
    func taskRegistration() async {
        let expectedBytes: Int64 = 12345
        
        let sut = CameraUploadTransferProgressRepository()
        
        var phaseAsyncIterator = await sut.cameraUploadPhaseEventUpdates.makeAsyncIterator()
        var progressAsyncIterator = await sut.progressRawDataUpdates(for: taskInfo.localIdentifier)
            .makeAsyncIterator()
        await sut.registerTask(identifier: 1, info: taskInfo, totalBytesExpectedToWrite: expectedBytes)
        
        #expect(await sut.activeUploads == [taskInfo.localIdentifier])
        
        #expect(await phaseAsyncIterator.next() == CameraUploadPhaseEventEntity(
            assetIdentifier: taskInfo.localIdentifier,
            phase: .registered))
        
        let progress = await progressAsyncIterator.next()
        #expect(progress?.totalBytesSent == 0)
        #expect(progress?.totalBytesExpected == expectedBytes)
        #expect(progress?.speedSamples.count == 1)
        #expect(progress?.speedSamples.first?.bytesSent == 0)
    }
    
    @Test
    func updateProgress() async {
        let localIdentifier = "identifier"
        let firstChunkTotalBytesSent: Int64 = 12345
        let firstChunkTotalBytesSentAgain: Int64 = 12350
        let secondChunkTotalBytesSent: Int64 = 23456
        let fileRegistrationBytesExpected: Int64 = 123
        let firstChunkTotalBytesExpected: Int64 = 54321
        let secondChunkTotalBytesExpected: Int64 = 65432
        let firstTaskInfo = CameraUploadTaskInfoEntity(localIdentifier: localIdentifier, chunkIndex: 0, totalChunks: 2)
        let secondTaskInfo = CameraUploadTaskInfoEntity(localIdentifier: localIdentifier, chunkIndex: 1, totalChunks: 2)
        
        let sut = CameraUploadTransferProgressRepository()
        await sut.registerTask(identifier: 1, info: firstTaskInfo, totalBytesExpectedToWrite: firstChunkTotalBytesExpected)
        await sut.registerTask(identifier: 2, info: secondTaskInfo, totalBytesExpectedToWrite: fileRegistrationBytesExpected)
        
        var phaseAsyncIterator = await sut.cameraUploadPhaseEventUpdates.makeAsyncIterator()
        var iterator = await sut.progressRawDataUpdates(for: localIdentifier).makeAsyncIterator()
        
        await sut.updateTaskProgress(
            identifier: 1,
            info: firstTaskInfo,
            totalBytesSent: firstChunkTotalBytesSent,
            totalBytesExpected: firstChunkTotalBytesExpected)
        
        #expect(await phaseAsyncIterator.next() == CameraUploadPhaseEventEntity(
            assetIdentifier: localIdentifier,
            phase: .uploading))
        
        let firstProgress = await iterator.next()
        #expect(firstProgress?.totalBytesSent == firstChunkTotalBytesSent)
        #expect(firstProgress?.totalBytesExpected == firstChunkTotalBytesExpected + fileRegistrationBytesExpected)
        #expect(firstProgress?.speedSamples.count == 3)
        
        await sut.updateTaskProgress(
            identifier: 1,
            info: firstTaskInfo,
            totalBytesSent: firstChunkTotalBytesSentAgain,
            totalBytesExpected: firstChunkTotalBytesExpected)
        
        let secondProgress = await iterator.next()
        #expect(secondProgress?.totalBytesSent == firstChunkTotalBytesSentAgain)
        
        await sut.updateTaskProgress(
            identifier: 2,
            info: secondTaskInfo,
            totalBytesSent: secondChunkTotalBytesSent,
            totalBytesExpected: secondChunkTotalBytesExpected)
        
        let thirdProgress = await iterator.next()
        #expect(thirdProgress?.totalBytesSent == firstChunkTotalBytesSentAgain + secondChunkTotalBytesSent)
        #expect(thirdProgress?.totalBytesExpected == firstChunkTotalBytesExpected + secondChunkTotalBytesExpected)
    }
    
    @Test func completeTask() async {
        let sut = CameraUploadTransferProgressRepository()
        await sut.registerTask(identifier: 1, info: taskInfo, totalBytesExpectedToWrite: 800)
        var phaseAsyncIterator = await sut.cameraUploadPhaseEventUpdates.makeAsyncIterator()
        
        await sut.completeTask(identifier: 1, info: taskInfo)
        #expect(await phaseAsyncIterator.next() == CameraUploadPhaseEventEntity(
            assetIdentifier: taskInfo.localIdentifier,
            phase: .completed))
    }
    
    @Test func restoreTasks() async {
        let currentBytes: Int64 = 12345
        let expectedBytes: Int64 = 54321
        
        let sut = CameraUploadTransferProgressRepository()
        var iterator = await sut.progressRawDataUpdates(for: taskInfo.localIdentifier).makeAsyncIterator()
        await sut.registerTask(identifier: 1, info: taskInfo, totalBytesExpectedToWrite: 800)
        #expect(await iterator.next() != nil)
        
        await sut.restoreTasks(
            for: taskInfo.localIdentifier,
            taskIdentifierForChunk: [2: taskInfo.chunkIndex],
            totalBytesSent: currentBytes,
            expectedBytesPerChunk: [0: expectedBytes])
        
        let progress = await iterator.next()
        #expect(progress?.totalBytesSent == currentBytes)
        #expect(progress?.totalBytesExpected == expectedBytes)
        
        #expect(await sut.activeUploads == [taskInfo.localIdentifier])
    }
}
