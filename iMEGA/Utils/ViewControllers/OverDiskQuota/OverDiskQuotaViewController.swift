import UIKit

class OverDiskQuotaViewController: UIViewController {
    
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ""
        navigationController?.navigationBar.setTranslucent()
        navigationController?.setTitleStyle(TextStyle(font: .navigationBarTitleFont, color: .white))
        disableAdjustingContentInsets(ofScrollView: contentScrollView)
    }
}
