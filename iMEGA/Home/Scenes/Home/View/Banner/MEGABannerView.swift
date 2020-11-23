import UIKit

final class MEGABannerView: UIView, NibOwnerLoadable {

    struct Banner {
        let title: String
        let detail: String
        let image: UIImage
    }

    @IBOutlet private weak var carouselCollectionView: UICollectionView!

    @IBOutlet weak var carouselCollectionViewLayout: MEGACarouselFlowLayout!

    @IBOutlet private weak var carouselPageControl: UIPageControl!

    private var bannerDataSource: [Banner] = [
        Banner(title: "", detail: "", image: UIImage()),
        Banner(title: "", detail: "", image: UIImage()),
        Banner(title: "", detail: "", image: UIImage()),
        Banner(title: "", detail: "", image: UIImage()),
        Banner(title: "", detail: "", image: UIImage()),
        Banner(title: "", detail: "", image: UIImage()),
        Banner(title: "", detail: "", image: UIImage()),

    ]

    private var itemSize: CGSize!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Privates

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        loadNibContent()

        // MARK: - initialize

        initialiseCollectionView()
        initialiseCollectionViewLayout()
        carouselPageControl.numberOfPages = bannerDataSource.count
        carouselPageControl.currentPage = 0
    }

    private func initialiseCollectionView() {
        carouselCollectionView.translatesAutoresizingMaskIntoConstraints = false
        carouselCollectionView.backgroundColor = .darkGray
        carouselCollectionView.isPagingEnabled = false
        carouselCollectionView.showsHorizontalScrollIndicator = false

        carouselCollectionView.dataSource = self
        carouselCollectionView.register(
            UINib(nibName: CarouselCollection.cell.rawValue, bundle: nil),
            forCellWithReuseIdentifier: CarouselCollection.cell.rawValue
        )
    }

    private func initialiseCollectionViewLayout() {
        carouselCollectionViewLayout.scrollDirection = .horizontal
        carouselCollectionViewLayout.delegate = self
    }

    // MARK: - UIView overrides

    override func layoutSubviews() {
        super.layoutSubviews()

        if itemSize == nil || itemSize != bounds.size {
            let collectionViewSize = CGSize(width: bounds.size.width, height: 90)
            itemSize = collectionViewSize
            carouselCollectionViewLayout.itemSize = itemSize
        }
    }
}

extension MEGABannerView: UICollectionViewDataSource {

    private enum CarouselCollection: String {
        case cell = "BannerCarouselCollectionViewCell"
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        bannerDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CarouselCollection.cell.rawValue,
            for: indexPath
        )
        return cell
    }
}

extension MEGABannerView: MEGACarouselFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        collectionViewLayout: MEGACarouselFlowLayout,
                        didScrollToPage page: Int) {
        carouselPageControl.currentPage = page
    }
}
