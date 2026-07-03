@preconcurrency import Combine
import MEGAAppSDKRepo
import MEGAConnectivity
import MEGADomain
import SwiftUI

// NOTE: Duplicated verbatim from Home's `NetworkPathConnectionUseCase`. Bridges the domain
// `NetworkMonitorUseCase` (raw NWPath) to MEGAConnectivity's `ConnectionUseCaseProtocol` so the
// shared no-internet prompt clears promptly on reconnect (the default source polls a health-check
// URL and lags). Pending de-dup into a single shared implementation — see IOS-12145.
private final class NetworkPathConnectionUseCase: ConnectionUseCaseProtocol, Sendable {
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

struct TransfersNoInternetViewModifier: ViewModifier {
    @StateObject private var viewModel = NoInternetViewModel(
        connectionUseCase: NetworkPathConnectionUseCase(
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo)
        )
    )

    func body(content: Content) -> some View {
        content.modifier(NoInternetViewModifier(layout: .inline, viewModel: viewModel))
    }
}
