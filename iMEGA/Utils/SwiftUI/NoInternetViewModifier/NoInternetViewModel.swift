import Foundation
import MEGADomain

final class NoInternetViewModel: ObservableObject {
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol

    @Published private(set) var isConnected = true
    typealias NetworkConnectionStateChanged = (Bool) -> Void
    var networkConnectionStateChanged: NetworkConnectionStateChanged?

    init(
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        networkConnectionStateChanged: NetworkConnectionStateChanged? = nil
    ) {
        self.networkMonitorUseCase = networkMonitorUseCase
        self.networkConnectionStateChanged = networkConnectionStateChanged
    }

    @MainActor
    func onTask() async {
        self.isConnected = networkMonitorUseCase.isConnected()
        await monitorNetworkChanges()
    }

    @MainActor
    private func monitorNetworkChanges() async {
        for await isConnected in networkMonitorUseCase.connectionSequence.removeDuplicates() {
            networkConnectionStateChanged?(isConnected)
            self.isConnected = isConnected
        }
    }
}
