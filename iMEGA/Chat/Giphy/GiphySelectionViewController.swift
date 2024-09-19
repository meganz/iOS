import MEGAL10n
import MEGAUIKit
import UIKit

class GiphySelectionViewController: UIViewController {
    
    private var mainView: GiphySelectionView {
        return self.view as! GiphySelectionView
    }
    
    let chatRoom: MEGAChatRoom!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    init(chatRoom: MEGAChatRoom) {
        self.chatRoom = chatRoom

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = GiphySelectionView(controller: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.localized("Send GIF", comment: "")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.placeholder = Strings.localized("Search GIPHY", comment: "")
        definesPresentationContext = true
        
        searchController.searchBar.delegate = mainView
        searchController.delegate = mainView
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        navigationController?.isToolbarHidden = false
        let giphyIconItem = UIBarButtonItem(image: UIImage.poweredByGIPHY, style: .plain, target: nil, action: nil)
        toolbarItems = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                        giphyIconItem,
                        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)]
        
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar, 
                                               backgroundColorWhenDesignTokenEnable: UIColor.surface1Background(),
                                               traitCollection: self.traitCollection)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        mainView.viewOrientationDidChange()
    }
}

extension GiphySelectionViewController: TraitEnvironmentAware {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        AppearanceManager.forceSearchBarUpdate(searchController.searchBar, 
                                               backgroundColorWhenDesignTokenEnable: UIColor.surface1Background(),
                                               traitCollection: currentTrait)
    }
}
