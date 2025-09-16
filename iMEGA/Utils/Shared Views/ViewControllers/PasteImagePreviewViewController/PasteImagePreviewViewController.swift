import UIKit

class PasteImagePreviewViewController: UIViewController {

    let presentationManager = MEGAPresentationManager()

    private var mainView: PasteImagePreviewView {
        return self.view as! PasteImagePreviewView
    }
    
    // MARK: - Internal properties
    var viewModel: PasteImagePreviewViewModel!

    // This extends the superclass.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.transitioningDelegate = presentationManager
        self.modalPresentationStyle = .custom
    }

    // This is also necessary when extending the superclass.
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") // or see Roman Sausarnes's answer
    }
    
    override func loadView() {
        view = PasteImagePreviewView(viewModel: viewModel)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        mainView.viewOrientationDidChange()
    }

}
