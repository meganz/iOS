@preconcurrency import Combine
import MEGAConnectivity
import MEGADomain

final class NetworkPathConnectionUseCase: ConnectionUseCaseProtocol, Sendable {
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let _isConnectedPublisher: AnyPublisher<Bool, Never>
    private let _connectivityStatusPublisher: AnyPublisher<ConnectivityStatus, Never>
    private let monitorTask: Task<Void, Never>

    var isConnected: Bool { networkMonitorUseCase.isConnected() }
    var isNetworkConnected: Bool { networkMonitorUseCase.isConnected() }
    var isConnectedPublisher: AnyPublisher<Bool, Never> { _isConnectedPublisher }
    var connectivityStatus: ConnectivityStatus { isConnected ? .connectedToInternet : .disconnected }
    var connectivityStatusPublisher: AnyPublisher<ConnectivityStatus, Never> { _connectivityStatusPublisher }

    init(networkMonitorUseCase: some NetworkMonitorUseCaseProtocol) {
        self.networkMonitorUseCase = networkMonitorUseCase
        let subject = CurrentValueSubject<Bool, Never>(networkMonitorUseCase.isConnected())
        _isConnectedPublisher = subject.removeDuplicates().eraseToAnyPublisher()
        _connectivityStatusPublisher = subject.removeDuplicates()
            .map { $0 ? ConnectivityStatus.connectedToInternet : .disconnected }
            .eraseToAnyPublisher()
        monitorTask = Task {
            for await connected in networkMonitorUseCase.connectionSequence {
                subject.send(connected)
            }
        }
    }

    deinit {
        monitorTask.cancel()
    }
}
