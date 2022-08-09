
import Foundation

enum TermsAndPoliciesCell: Int {
    case privacyPolicy
    case cookiePolicy
    case termsOfService
}

class TermsAndPoliciesTableViewController: UITableViewController {
    
    @IBOutlet weak var privacyPolicyLabel: UILabel!
    @IBOutlet weak var cookiePolicyLabel: UILabel!
    @IBOutlet weak var termsOfServiceLabel: UILabel!
    
    weak var router: TermsAndPoliciesRouter!
    var viewModel: TermsAndPoliciesViewModel!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configView()
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
        title = Strings.Localizable.Settings.Section.termsAndPolicies
        
        privacyPolicyLabel.text = Strings.Localizable.privacyPolicyLabel
        cookiePolicyLabel.text = Strings.Localizable.General.cookiePolicy
        termsOfServiceLabel.text = Strings.Localizable.termsOfServicesLabel
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        tableView.backgroundColor = .mnz_backgroundGrouped(for: traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension TermsAndPoliciesTableViewController {
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .mnz_secondaryBackgroundGrouped(traitCollection)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case TermsAndPoliciesCell.privacyPolicy.rawValue:
            viewModel.dispatch(.showPrivacyPolicy)
            
        case TermsAndPoliciesCell.cookiePolicy.rawValue:
            viewModel.dispatch(.showCookiePolicy)
            
        case TermsAndPoliciesCell.termsOfService.rawValue:
            viewModel.dispatch(.showTermsOfService)
            
        default:
            break
        }
    }
}
