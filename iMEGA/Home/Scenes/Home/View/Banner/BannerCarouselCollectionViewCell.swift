import UIKit

class BannerCarouselCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var bannerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        bannerView.layer.borderColor = UIColor.red.cgColor
        bannerView.layer.borderWidth = 1
        bannerView.layer.cornerRadius = 10
        bannerView.layer.masksToBounds = true
    }

}
