import MEGAUIKit
import UIKit

protocol MEGABannerViewDelegate: AnyObject {
    func didScrollMEGABannerView()
    
    func dismissMEGABanner(_ bannerView: MEGABannerView, withBannerIdentifier bannerIdentifier: Int)

    func didSelectMEGABanner(withBannerIdentifier bannerIdentifier: Int, actionURL: URL?)

    func hideMEGABannerView(_ bannerView: MEGABannerView)
}

final class MEGABannerView: UIView, NibOwnerLoadable {

    struct Banner {
        let identifier: Int
        let title: String
        let detail: String
        let iconImage: URL
        let backgroundImage: URL
        let actionURL: URL?

        let dismissAction: ((Int) -> Void)?
    }

    @IBOutlet private var rootView: UIView!

    @IBOutlet private var carouselCollectionView: UICollectionView!

    @IBOutlet private var carouselCollectionViewLayout: MEGACarouselFlowLayout!

    @IBOutlet private var carouselPageControl: UIPageControl!

    @IBOutlet weak var carouselCollectionViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: (any MEGABannerViewDelegate)?

    private var bannerDataSource: [Banner] = []

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

        styleView(with: traitCollection)
    }

    private func styleView(with trait: UITraitCollection) {
        trait.theme.customViewStyleFactory.styler(of: .homeBannerView)(rootView)

        let styling = trait.theme.customViewStyleFactory.styler(of: .homeCarouselCollectionView)
        styling(carouselCollectionView)
        if let carouselCollectionViewBackgroundView = carouselCollectionView.backgroundView {
            styling(carouselCollectionViewBackgroundView)
        }
        styleCarouselPageControl(carouselPageControl, with: trait)
    }

    private func styleCarouselPageControl(_ pageControl: UIPageControl, with trait: UITraitCollection) {
        trait.theme.pageControlStyleFactory.styler(of: .homeBanner)(pageControl)
    }

    private func initialiseCollectionView() {
        carouselCollectionView.translatesAutoresizingMaskIntoConstraints = false
        carouselCollectionView.isPagingEnabled = true
        carouselCollectionView.showsHorizontalScrollIndicator = false
        carouselCollectionView.backgroundView = UIView(frame: .zero)

        carouselCollectionView.dataSource = self
        carouselCollectionView.delegate = self
        carouselCollectionView.register(
            UINib(nibName: CarouselCollection.cell.rawValue, bundle: nil),
            forCellWithReuseIdentifier: CarouselCollection.cell.rawValue
        )
    }

    private func initialiseCollectionViewLayout() {
        carouselCollectionViewLayout.scrollDirection = .horizontal
        carouselCollectionViewLayout.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        refreshContainer()
    }
    
    // MARK: - Public Interface
    
    func reloadBanners(_ bannerDisplayModels: [HomeBannerDisplayModel.Banner]) {
        let bannerCollectionModels = bannerDisplayModels.map { [weak self] (banner) -> Banner in
            Banner(
                identifier: banner.identifier,
                title: banner.title,
                detail: banner.description,
                iconImage: banner.image,
                backgroundImage: banner.backgroundImage,
                actionURL: banner.actionURL,
                dismissAction: { bannerIdentifier in
                    self?.removeBanner(withIdentifier: bannerIdentifier)
                }
            )
        }
        bannerDataSource = bannerCollectionModels
        calculateCarouselItemSize()
        carouselCollectionView.reloadData()
        carouselPageControl.numberOfPages = bannerDataSource.count
        carouselPageControl.currentPage = 0
    }
    
    func refreshContainer() {
        calculateCarouselItemSize()
        carouselCollectionViewLayout.updateLayout()
        carouselCollectionView.reloadData()
    }

    private func removeBanner(withIdentifier identifierOfToBeRemovedBanner: Int) {
        guard let indexOfToBeRemovedBanner = (bannerDataSource.firstIndex { banner -> Bool in
            banner.identifier == identifierOfToBeRemovedBanner
        }) else { return }

        self.delegate?.dismissMEGABanner(self, withBannerIdentifier: identifierOfToBeRemovedBanner)

        var bannerDataSourceWithoutDismissedBanner = self.bannerDataSource
        bannerDataSourceWithoutDismissedBanner.remove(at: indexOfToBeRemovedBanner)

        carouselCollectionView.performBatchUpdates { [weak self] in
            guard let self else { return }
            
            self.bannerDataSource = bannerDataSourceWithoutDismissedBanner
            self.carouselCollectionView.deleteItems(at: [IndexPath(row: indexOfToBeRemovedBanner, section: 0)])
        } completion: { [weak self] _ in
            guard let self else { return }

            self.carouselPageControl.numberOfPages = self.bannerDataSource.count
            if bannerDataSourceWithoutDismissedBanner.isEmpty {
                self.delegate?.hideMEGABannerView(self)
            }
        }
    }
    
    private func calculateCarouselItemSize() {
        let collectionViewSize = CGSize(width: carouselCollectionView.bounds.width, height: calculateBannerMaxHeight(bannerDataSource))
        itemSize = collectionViewSize
        carouselCollectionViewLayout.itemSize = itemSize
        carouselCollectionViewHeightConstraint.constant = itemSize.height
        carouselCollectionView.layoutIfNeeded()
    }
    
    private func calculateBannerMaxHeight(_ banners: [Banner]) -> CGFloat {
        banners.reduce(0.0) {
            max($0, BannerCarouselCollectionViewCell.height($1, width: carouselCollectionView.bounds.width))
        }
    }
}

extension MEGABannerView: UICollectionViewDataSource, UICollectionViewDelegate {

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
        ) as! BannerCarouselCollectionViewCell
        cell.configure(with: bannerDataSource[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedBanner =  bannerDataSource[indexPath.row]
        delegate?.didSelectMEGABanner(
            withBannerIdentifier: selectedBanner.identifier,
            actionURL: selectedBanner.actionURL
        )
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.didScrollMEGABannerView()
    }
}

extension MEGABannerView: MEGACarouselFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        collectionViewLayout: MEGACarouselFlowLayout,
                        didScrollToPage page: Int) {
        carouselPageControl.currentPage = page
    }
}

// MARK: - TraitEnvironmentAware

extension MEGABannerView: TraitEnvironmentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            calculateCarouselItemSize()
            carouselCollectionView.reloadData()
        }
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        styleView(with: currentTrait)
    }
}
