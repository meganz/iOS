import FlexLayout
import MEGAAssets
import MEGAL10n
import PinLayout
import UIKit

class GiphySelectionView: UIView {
    private let contentView = UIView()
    lazy var categoryView: GiphyCategoryView = {
        let view = GiphyCategoryView()
        view.onSelected = { [weak self] category in
            guard category != self?.category, let self = self else {
                return
            }
            self.category = category
            self.collectionView.reloadData()
            self.requestGiphy()
        }
        return view
    }()

    lazy var collectionView: UICollectionView = {
        UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    }()

    lazy var flowLayout: CHTCollectionViewWaterfallLayout = {
        // Create a waterfall layout
        let layout = CHTCollectionViewWaterfallLayout()
        configureLayout(layout)
        return layout
    }()

    var gifs: [GiphyResponseModel] = []
    var stickers: [GiphyResponseModel] = []
    var text: [GiphyResponseModel] = []
    var emoji: [GiphyResponseModel] = []

    var filteredGifs: [GiphyResponseModel] = []
    var category: GiphyCatogory = .gifs

    var searchKey = ""

    var datasource: [GiphyResponseModel] {
        get {
            if searchKey.isEmpty {
                switch category {
                case .gifs:
                    return gifs
                case .stickers:
                    return stickers
                case .text:
                    return text
                case .emoji:
                    return emoji
                }
            } else {
                return filteredGifs
            }
        }
        set {
            if searchKey.isEmpty {
                switch category {
                case .gifs:
                    gifs = newValue
                case .stickers:
                    stickers = newValue
                case .text:
                    text = newValue
                case .emoji:
                    emoji = newValue
                }
            } else {
                filteredGifs = newValue
            }
        }
    }

    weak var controller: GiphySelectionViewController!
    var requestTask: URLSessionDataTask?
    
    init(controller: GiphySelectionViewController) {
        self.controller = controller
        super.init(frame: .zero)

        backgroundColor = UIColor.systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .onDrag
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        // attach the UI nib file for the ImageUICollectionViewCell to the collectionview
        let viewNib = UINib(nibName: "MEGAGiphyCollectionViewCell", bundle: nil)
        collectionView.register(viewNib, forCellWithReuseIdentifier: "cell")
        contentView.flex.define { flex in
            flex.addItem(collectionView).grow(1).shrink(1)
        }

        addSubview(contentView)

        requestGiphy()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func requestGiphy() {
        requestTask?.cancel()
        requestTask = Services.getGiphyStickers(searchKey: searchKey, offset: datasource.count, category: category) { result in

            switch result {
            case let Result.success(response):
                if self.searchKey.isEmpty {
                    switch self.category {
                    case .gifs:
                        self.gifs += response
                    case .stickers:
                        self.stickers += response
                    default:
                        break
                    }
                } else {
                    self.filteredGifs += response
                }
            case Result.failure:
                // Handle error
                break
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
        collectionView.reloadEmptyDataSet()
    }
    
    private func configureLayout(_ layout: CHTCollectionViewWaterfallLayout) {
        // Change individual layout attributes for the spacing between cells
        layout.minimumColumnSpacing = 8
        layout.minimumInteritemSpacing = 8
        if UIDevice.current.orientation.isLandscape {
            layout.columnCount = 4
        } else {
            layout.columnCount = 2
        }
    }
    
    func viewOrientationDidChange() {
        configureLayout(flowLayout)
        flowLayout.invalidateLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.pin.all()

        contentView.flex.layout()
    }
}

extension GiphySelectionView: CHTCollectionViewDelegateWaterfallLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    // ** Create a basic CollectionView Cell */
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create the cell and return the cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MEGAGiphyCollectionViewCell
        let gif = datasource[indexPath.item]

        // Add image to cell
        cell.image.sd_setImage(with: URL(string: gif.webp))
        cell.image.backgroundColor = UIColor(patternImage: MEGAAssets.UIImage.giphyCellBackground)
        return cell
    }

    // MARK: - CollectionView Delegate Methods

    // ** Number of Cells in the CollectionView */
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return datasource.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let previewVC = GiphyPreviewViewController()
        previewVC.giphy = datasource[indexPath.item]
        previewVC.onCompleted = { [weak self] gif in
            guard let gif = gif,
                  let sizeMp4 = UInt64(gif.mp4_size),
                  let sizeWebp = UInt64(gif.webp_size),
                  let width = Int32(gif.width),
                  let height = Int32(gif.height),
                  let self = self else {
                return
            }
            
            let srcWebp = gif.webp.replacingOccurrences(of: ServiceManager.shared.BASE_URL, with: ServiceManager.shared.GIPHY_URL)
            let srcMp4 = gif.mp4.replacingOccurrences(of: ServiceManager.shared.BASE_URL, with: ServiceManager.shared.GIPHY_URL)

            MEGAChatSdk.shared.sendGiphy(toChat: self.controller.chatRoom.chatId, srcMp4: srcMp4, srcWebp: srcWebp, sizeMp4: sizeMp4, sizeWebp: sizeWebp, width: width, height: height, title: gif.title)
            self.controller.navigationController?.dismiss(animated: true, completion: nil)
        }
        controller.navigationController?.pushViewController(previewVC, animated: true)
    }

    // MARK: - CollectionView Waterfall Layout Delegate Methods (Required)

    // ** Size for the cells in the Waterfall Layout */
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // create a cell size from the image size, and return the size
        let gif = datasource[indexPath.item]
        guard let width = Int(gif.width), let height = Int(gif.height) else {
            return .zero
        }

        let imageSize = CGSize(width: width, height: height)
        return imageSize
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height

        if offsetY > contentHeight - scrollView.frame.height * 4, requestTask?.state != .running {
            requestGiphy()
        }
    }
}

extension GiphySelectionView: UISearchBarDelegate, UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            return
        }
        searchKey = text
        collectionView.reloadData()
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, text != searchKey else {
            return
        }
        searchKey = text
        filteredGifs = []
        collectionView.reloadData()
        requestGiphy()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let text = searchBar.text, text != searchKey else {
            return
        }
        searchKey = text
        filteredGifs = []
        collectionView.reloadData()
        debounce(#selector(requestGiphy), delay: 0.1)
        
    }
}

extension GiphySelectionView: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func title(forEmptyDataSet _: UIScrollView) -> NSAttributedString? {
        let title = NSAttributedString(string: Strings.localized("No GIFs found", comment: ""),
                                       attributes: [
                                        NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.5),
                                        NSAttributedString.Key.font: UIFont.preferredFont(style: .body, weight: .semibold)
                                       ])
        return title
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        MEGAAssets.UIImage.noGIF
    }

    func customView(forEmptyDataSet _: UIScrollView) -> UIView? {
        if requestTask?.state == .running {
            let activityView = UIActivityIndicatorView(style: .medium)
            activityView.startAnimating()
            return activityView
        } else {
            return nil
        }
    }

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return datasource.isEmpty || requestTask?.state == .running
    }
}
