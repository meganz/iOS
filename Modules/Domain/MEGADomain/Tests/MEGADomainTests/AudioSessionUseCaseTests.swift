import Combine
import MEGADomain
import MEGADomainMock
import Testing

@Suite("AudioSessionUseCase Unit tests")
struct AudioSessionUseCaseTests {
    private static func makeSUT() -> (useCase: AudioSessionUseCase<MockAudioSessionRepository>, mockRepo: MockAudioSessionRepository) {
        let mock = MockAudioSessionRepository()
        let useCase = AudioSessionUseCase(audioSessionRepository: mock)
        return (useCase, mock)
    }
    
    @Suite("AudioSessionUseCase: Properties passthrough")
    struct AudioSessionUseCasePropertiesTests {
        
        @Test(
            "isBluetoothAudioRouteAvailable_passthroughsValue",
            arguments: [true, false]
        )
        func isBluetoothAudioRouteAvailable_passthroughsValue(_ expected: Bool) {
            let (useCase, mock) = makeSUT()
            mock.isBluetoothAudioRouteAvailableStub = expected
            #expect(useCase.isBluetoothAudioRouteAvailable == expected)
        }
        
        @Test(
            "currentSelectedAudioPort_passthroughsValue",
            arguments: [AudioPort.unknown, .builtInSpeaker, .builtInReceiver, .headphones, .other]
        )
        func currentSelectedAudioPort_passthroughsValue(_ expected: AudioPort) {
            let (useCase, mock) = makeSUT()
            mock.currentSelectedAudioPortStub = expected
            #expect(useCase.currentSelectedAudioPort == expected)
        }
    }
    
    @Suite("AudioSessionUseCase: Configuration delegation")
    struct AudioSessionUseCaseConfigurationTests {
        
        @Test
        func configureDefaultAudioSession_delegates() {
            let (useCase, mock) = makeSUT()
            useCase.configureDefaultAudioSession()
            #expect(mock.configureDefaultCalledTimes == 1)
        }
        
        @Test
        func configureCallAudioSession_delegates() {
            let (useCase, mock) = makeSUT()
            useCase.configureCallAudioSession()
            #expect(mock.configureCallCalledTimes == 1)
        }
        
        @Test
        func configureAudioPlayerAudioSession_delegates() {
            let (useCase, mock) = makeSUT()
            useCase.configureAudioPlayerAudioSession()
            #expect(mock.configureAudioPlayerCalledTimes == 1)
        }
        
        @Test
        func configureChatDefaultAudioPlayer_delegates() {
            let (useCase, mock) = makeSUT()
            useCase.configureChatDefaultAudioPlayer()
            #expect(mock.configureChatDefaultPlayerCalledTimes == 1)
        }
        
        @Test(
            "configureAudioRecorderAudioSession_delegates_forAllVariants",
            arguments: [false, true]
        )
        func configureAudioRecorderAudioSession_delegates_forAllVariants(_ isPlayerAlive: Bool) {
            let (useCase, mock) = makeSUT()
            useCase.configureAudioRecorderAudioSession(isPlayerAlive: isPlayerAlive)
            #expect(mock.configureRecorderCalledTimes == 1)
        }
        
        @Test
        func configureVideoAudioSession_delegates() {
            let (useCase, mock) = makeSUT()
            useCase.configureVideoAudioSession()
            #expect(mock.configureVideoCalledTimes == 1)
        }
    }
    
    @Suite("AudioSessionUseCase: Speaker control delegation")
    struct AudioSessionUseCaseSpeakerControlTests {
        
        @Test
        func enableLoudSpeaker_delegates() {
            let (useCase, mock) = makeSUT()
            useCase.enableLoudSpeaker()
            #expect(mock.enableLoudSpeakerCalledTimes == 1)
        }
        
        @Test
        func disableLoudSpeaker_delegates() {
            let (useCase, mock) = makeSUT()
            useCase.disableLoudSpeaker()
            #expect(mock.disableLoudSpeakerCalledTimes == 1)
        }
    }
    
    @Suite("AudioSessionUseCase: Output check delegation")
    struct AudioSessionUseCaseOutputCheckTests {
        
        @Test(
            "isOutputFrom_delegatesAndReturnsRepositoryValue",
            arguments: [AudioPort.builtInSpeaker, .builtInReceiver, .headphones, .other, .unknown]
        )
        func isOutputFrom_delegatesAndReturnsRepositoryValue(_ queriedPort: AudioPort) {
            let (useCase, mock) = makeSUT()
            mock.currentSelectedAudioPortStub = .headphones
            
            let result = useCase.isOutputFrom(port: queriedPort)
            
            #expect(mock.isOutputFromCalledTimes == 1)
            #expect(mock.isOutputFromLastPort == queriedPort)
            #expect(result == (queriedPort == .headphones))
        }
    }
}
