
import Foundation

class ThirdPartyCookiesMoreInfoViewController: UIViewController {
    
    @IBOutlet weak var noThirdPartyCookiesInUseLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.toolbar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.toolbar.isHidden = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            AppearanceManager.forceNavigationBarUpdate(self.navigationController?.navigationBar ?? UINavigationBar(), traitCollection: traitCollection)
            
            updateAppearance()
        }
    }
    
    // MARK: - Private
    
    private func configView() {
        title = NSLocalizedString("Third Party Cookies", comment: "Cookie settings dialog link label. Should be same as in “24659” string.")
        
        noThirdPartyCookiesInUseLabel.text = NSLocalizedString("No Third Party Cookies in use", comment: "Text shown after clicking on 'More information' under the Third Party Cookies section when there are not used")
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
    }
}
