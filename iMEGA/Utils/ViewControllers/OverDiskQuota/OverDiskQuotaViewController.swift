import UIKit

class OverDiskQuotaViewController: UIViewController {
    
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationController(self.navigationController)
        setupScrollView(contentScrollView)
    }

    // MARK: - UI Customize

    private func setupNavigationController(_ navigationController: UINavigationController?) {
        title = "Stoage Full"
        navigationController?.navigationBar.setTranslucent()
        navigationController?.setTitleStyle(TextStyle(font: .header, color: Color.Text.lightPrimary))
    }

    private func setupScrollView(_ scrollView: UIScrollView) {
        disableAdjustingContentInsets(ofScrollView: contentScrollView)
    }
}
