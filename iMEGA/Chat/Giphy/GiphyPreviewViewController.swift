import MEGAAssets
import MEGAL10n
import UIKit

class GiphyPreviewViewController: UIViewController {

    lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var onCompleted: (_ giphy: GiphyResponseModel?) -> Void = {_ in } // closure must be held in this class.
    var giphy: GiphyResponseModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.Localizable.send, style: .plain, target: self, action: #selector(send(sender:)))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.preferredFont(style: .body, weight: .medium)], for: .normal)
        
        view.backgroundColor = UIColor.systemBackground
        view.addSubview(previewImageView)
        configurePreviewImage()
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get {
            return true
        }
        set {
            super.hidesBottomBarWhenPushed = newValue
        }
    }
    
    @objc func send(sender: UIBarButtonItem) {
        onCompleted(giphy)
    }
    
    private func configurePreviewImage() {
        previewImageView.contentMode = .scaleAspectFit

        guard let giphy = giphy,
              let ratio = giphy.sizeRatio else {
                  return
              }
       
        NSLayoutConstraint.activate([
            previewImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: ratio)
        ])
        
        previewImageView.sd_setImage(with: URL(string: giphy.webp))
        previewImageView.backgroundColor = UIColor(patternImage: MEGAAssets.UIImage.giphyCellBackground)
    }
}

private extension GiphyResponseModel {
    var floatWidth: CGFloat? {
        guard let width = Double(width) else {
            return nil
        }
        
        return CGFloat(width)
    }
    
    var floatHeight: CGFloat? {
        guard let height = Double(height) else {
            return nil
        }
        
        return CGFloat(height)
    }
    
    var sizeRatio: CGFloat? {
        guard let width = floatWidth,
              let height = floatHeight else {
                  return nil
              }
        
        return height / width
    }
}
