import FirebaseAppDistribution
import UIKit

extension AboutTableViewController {
    @objc func checkForFirebaseUpdates() {
        AppDistribution.appDistribution().checkForUpdate { [weak self] release, error in
            guard let release = release, error == nil else {
                if let error = error {
                    Task { @MainActor in
                        self?.showAlert(withError: error)
                    }
                }
                return
            }
            
            Task { @MainActor [displayVersion = release.displayVersion, buildVersion = release.buildVersion, downloadURL = release.downloadURL] in
                self?.showAlert(displayVersion: displayVersion, buildVersion: buildVersion, downloadURL: downloadURL)
            }
            
        }
    }
    
    private func showAlert(displayVersion: String, buildVersion: String, downloadURL: URL) {
        let title = "New Version Available"
        let message = "Version \(displayVersion)(\(buildVersion)) is available."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(
            UIAlertAction(title: "Update", style: .default) { _ in
                UIApplication.shared.open(downloadURL)
            }
        )
        
        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        )
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func showAlert(withError error: some Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        
        alertController.addAction(
            UIAlertAction(title: "OK", style: .cancel, handler: nil)
        )
        
        present(alertController, animated: true, completion: nil)
    }
    
}
