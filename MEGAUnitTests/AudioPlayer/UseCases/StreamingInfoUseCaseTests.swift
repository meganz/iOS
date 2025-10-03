@testable import MEGA
import MEGADomain
import Testing

@Suite("StreamingInfoUseCase")
struct StreamingInfoUseCaseTests {
    private static func makeSUT(repo: MockStreamingInfoRepository) -> StreamingInfoUseCase {
        StreamingInfoUseCase(streamingInfoRepository: repo)
    }
    
    @Suite("Fetch track")
    struct FetchTrackSuite {
        @Test(arguments: [
            (Result<Void, NodeInfoError>.success, true, Comment("success returns an AudioPlayerItem")),
            (Result<Void, NodeInfoError>.failure(.generic), false, Comment("failure returns nil item"))
        ])
        func fetchTrack_returnsExpectedItem(_ result: Result<Void, NodeInfoError>, _ hasItem: Bool, _ note: Comment) {
            let sut = makeSUT(repo: MockStreamingInfoRepository(result: result))
            let item = sut.fetchTrack(from: MEGANode())
            #expect((item != nil) == hasItem, note)
        }
    }
    
    @Suite("Streaming URL")
    struct StreamingURLSuite {
        @Test(arguments: [
            (Result<Void, NodeInfoError>.success, true, Comment("success returns a valid URL")),
            (Result<Void, NodeInfoError>.failure(.generic), false, Comment("failure returns nil URL"))
        ])
        func streamingURL_returnsExpectedValue_andCountsCalls(_ result: Result<Void, NodeInfoError>, _ hasURL: Bool, _ note: Comment) {
            let repo = MockStreamingInfoRepository(result: result)
            let sut = makeSUT(repo: repo)
            #expect(repo.pathFromNodeCallCount == 0)
            let url = sut.streamingURL(for: MEGANode())
            #expect((url != nil) == hasURL, note)
            #expect(repo.pathFromNodeCallCount == 1)
        }
        
        @Test("multiple calls increment pathFromNodeCallCount")
        func streamingURL_incrementsCallCountMultipleTimes() {
            let repo = MockStreamingInfoRepository(result: .success)
            let sut = makeSUT(repo: repo)
            _ = sut.streamingURL(for: MEGANode())
            _ = sut.streamingURL(for: MEGANode())
            #expect(repo.pathFromNodeCallCount == 2, Comment("each call should increment the counter"))
        }
    }
    
    @Suite("Server control")
    struct ServerControlSuite {
        @Test(arguments: [
            (false, true, Comment("initially stopped → after startServer should be running")),
            (true, false, Comment("initially running → after stopServer should be stopped"))
        ])
        func serverStartStop_togglesAndTracks(_ initial: Bool, _ expected: Bool, _ note: Comment) {
            let repo = MockStreamingInfoRepository(result: .success, isRunning: initial)
            let sut = makeSUT(repo: repo)
            
            if !initial {
                sut.startServer()
                #expect(repo.serverStartCallCount == 1, Comment("startServer forwarded"))
            } else {
                sut.stopServer()
                #expect(repo.serverStopCallCount == 1, Comment("stopServer forwarded"))
            }
            
            #expect(sut.isLocalHTTPServerRunning() == expected, note)
        }
    }
    
    @Suite("Server running state")
    struct ServerStateSuite {
        @Test(arguments: [
            (true, true, Comment("repo reports server is running")),
            (false, false, Comment("repo reports server is stopped"))
        ])
        func isLocalHTTPServerRunning_reflectsRepository(_ isRunning: Bool, _ expectedState: Bool, _ note: Comment) {
            let sut = makeSUT(repo: MockStreamingInfoRepository(result: .success, isRunning: isRunning))
            #expect(sut.isLocalHTTPServerRunning() == expectedState, note)
        }
    }
}
