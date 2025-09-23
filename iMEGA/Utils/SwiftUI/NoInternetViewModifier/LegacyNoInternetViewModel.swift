import Foundation
import MEGADomain
import MEGASwift

final class LegacyNoInternetViewModel: ObservableObject {
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
        await monitorNetworkChanges()
    }

    @MainActor
    private func monitorNetworkChanges() async {
        for await isConnected in networkMonitorUseCase.connectionSequence.prepend(networkMonitorUseCase.isConnected()).removeDuplicates() {
            networkConnectionStateChanged?(isConnected)
            self.isConnected = isConnected
        }
    }
}
