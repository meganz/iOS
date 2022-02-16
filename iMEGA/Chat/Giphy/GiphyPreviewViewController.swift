import UIKit

class GiphyPreviewViewController: UIViewController {

    var previewImageView: UIImageView = UIImageView.newAutoLayout()
    var onCompleted: (_ giphy: GiphyResponseModel?) -> Void = {_ in } // closure must be held in this class.
    var giphy: GiphyResponseModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.Localizable.send, style: .plain, target: self, action:#selector(send(sender:)))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.preferredFont(style: .body, weight: .medium)], for: .normal)
        
        view.backgroundColor = .mnz_background()
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
        
        previewImageView.autoCenterInSuperview()
        previewImageView.autoPinEdge(toSuperviewEdge: .left)
        previewImageView.autoPinEdge(toSuperviewEdge: .right)
        previewImageView.autoMatch(.height, to: .width, of: view, withMultiplier: ratio)
        previewImageView.sd_setImage(with: URL(string: giphy.webp))
        previewImageView.backgroundColor = UIColor(patternImage: Asset.Images.Chat.giphyCellBackground.image)
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
