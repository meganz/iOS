import UIKit
import FirebaseAppDistribution

extension AboutTableViewController {
    @objc func checkForFirebaseUpdates() {
        AppDistribution.appDistribution().checkForUpdate { [weak self] release, error in
            guard let release = release, error == nil else {
                if let error = error {
                    self?.showAlert(withError: error)
                }
                return
            }
            
            self?.showAlert(withRelease: release)
        }
    }
    
    private func showAlert(withRelease release: AppDistributionRelease) {
        let title = "New Version Available"
        let message = "Version \(release.displayVersion)(\(release.buildVersion)) is available."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(
            UIAlertAction(title: "Update", style: .default) { _ in
                UIApplication.shared.open(release.downloadURL)
            }
        )
        
        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        )
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func showAlert(withError error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        
        alertController.addAction(
            UIAlertAction(title: "OK", style: .cancel, handler: nil)
        )
        
        present(alertController, animated: true, completion: nil)
    }
    
}
