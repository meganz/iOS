import Combine
import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class NetworkMonitorUseCaseTests: XCTestCase {
    private var cancellable: Set<AnyCancellable> = []
    
    private func makeSUT(
        connected: Bool = false,
        connectedViaWiFi: Bool = false,
        connectionChangedStream: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        networkPathChangedPublisher: AnyPublisher<Bool, Never> = Just(false).eraseToAnyPublisher()
    ) -> NetworkMonitorUseCase {
        let repo = MockNetworkMonitorRepository(
            connected: connected,
            connectedViaWiFi: connectedViaWiFi,
            connectionChangedStream: connectionChangedStream,
            networkPathChangedPublisher: networkPathChangedPublisher
        )
        return NetworkMonitorUseCase(repo: repo)
    }
    
    private func evaluatePublisher(
        _ publisher: AnyPublisher<Bool, Never>,
        expectedValues: [Bool],
        expectationDescription: String
    ) {
        let expectation = self.expectation(description: expectationDescription)
        expectation.expectedFulfillmentCount = expectedValues.count
        
        var receivedValues: [Bool] = []
        
        publisher
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellable)
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(receivedValues, expectedValues)
    }

    func testNetworkPathChangedPublisher_whenConnected_shouldReturnTrue() {
        let sut = makeSUT(
            connected: true,
            networkPathChangedPublisher: Just(true).eraseToAnyPublisher()
        )
        
        evaluatePublisher(
            sut.networkPathChangedPublisher,
            expectedValues: [true],
            expectationDescription: "Network is connected"
        )
    }
    
    func testNetworkPathChangedPublisher_whenNotConnected_shouldReturnFalse() {
        let sut = makeSUT(
            connected: false,
            networkPathChangedPublisher: Just(false).eraseToAnyPublisher()
        )
        
        evaluatePublisher(
            sut.networkPathChangedPublisher,
            expectedValues: [false],
            expectationDescription: "Network is not connected"
        )
    }
    
    func testNetworkPathChangedPublisher_networkChangedFromNotConnectedToConnected_success() {
        let initialPublisher = PassthroughSubject<Bool, Never>()
        let sut = makeSUT(networkPathChangedPublisher: initialPublisher.eraseToAnyPublisher())
        
        let expectation = self.expectation(description: "Network changed from not connected to connected")
        expectation.expectedFulfillmentCount = 2
        
        var receivedValues: [Bool] = []
        
        sut.networkPathChangedPublisher
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellable)
        
        initialPublisher.send(false)
        initialPublisher.send(true)
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(receivedValues, [false, true])
    }
    
    func testNetworkPathChangedPublisher_networkChangedFromConnectedToNotConnected_success() {
        let initialPublisher = PassthroughSubject<Bool, Never>()
        let sut = makeSUT(networkPathChangedPublisher: initialPublisher.eraseToAnyPublisher())
        
        let expectation = self.expectation(description: "Network changed from connected to not connected")
        expectation.expectedFulfillmentCount = 2
        
        var receivedValues: [Bool] = []
        
        sut.networkPathChangedPublisher
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellable)
        
        initialPublisher.send(true)
        initialPublisher.send(false)
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(receivedValues, [true, false])
    }
    
    func testConnectionChangedStream_onNetworkChanges_shouldChange() async {
        var expectedResults = [true, false, true]
        let connectionChanged = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield(expectedResult)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let sut = makeSUT(connectionChangedStream: connectionChanged)
        
        var receivedResults = [Bool]()
        
        for await isConnected in sut.connectionChangedStream {
            receivedResults.append(isConnected)
        }
        
        XCTAssertEqual(receivedResults, [true, false, true])
    }
    
    func testIsConnectedViaWiFi_whenConnectedViaWiFi_shouldReturnTrue() {
        let sut = makeSUT(connectedViaWiFi: true)
        XCTAssertTrue(sut.isConnectedViaWiFi())
    }
    
    func testIsConnectedViaWiFi_whenNotConnectedViaWiFi_shouldReturnFalse() {
        let sut = makeSUT(connectedViaWiFi: false)
        XCTAssertFalse(sut.isConnectedViaWiFi())
    }
}
