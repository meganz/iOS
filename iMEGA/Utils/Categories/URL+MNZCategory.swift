import Foundation
import MEGAAppSDKRepo
import MEGADomain

/// This Extension is created to support Swift first code and migrated from old Objective-C mnz_updatedURLWithCurrentAddress.
extension URL {
    
    func updatedURLWithCurrentAddress() -> URL {
        
        if !makeNetworkMonitorUseCase().isConnectedViaWiFi() {
            return self
        }
        
        // @see MegaTCPServer::getLink
        let loopbackAddress = "[::1]"
        let currentAddress = MEGAReachabilityManager.shared().currentAddress
        if let currentAddress = currentAddress {
            let urlString = self.absoluteString.replacingOccurrences(of: loopbackAddress, with: currentAddress)
            return URL(string: urlString) ?? self
        } else {
            return self
        }
    }
    
    private func makeNetworkMonitorUseCase() -> some NetworkMonitorUseCaseProtocol {
        let repository = NetworkMonitorRepository.newRepo
        let useCase = NetworkMonitorUseCase(repo: repository)
        return useCase
    }
}
