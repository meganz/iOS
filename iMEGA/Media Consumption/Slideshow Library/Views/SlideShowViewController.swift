import UIKit

protocol SlideShowInteraction {
    func singleTapOnSlideshow()
}

final class SlideShowViewController: UIViewController, ViewType {
    private var viewModel: SlideShowViewModel?
    
    @IBOutlet var collectionView: SlideShowCollectionView!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var bottomToolbar: UIToolbar!
    @IBOutlet var statusBarBackground: UIView!
    @IBOutlet var bottomBarBackground: UIView!
    @IBOutlet var btnPlay: UIBarButtonItem!
    
    private var slideShowTimer = Timer()
    
    private lazy var backgroundColor: UIColor = {
        UIColor.mnz_mainBars(for: traitCollection)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        statusBarBackground.backgroundColor = backgroundColor
        navigationBar.backgroundColor = backgroundColor
        bottomBarBackground.isHidden = true
        btnPlay.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal, style: .plain, barMetrics: .default)
        
        collectionView.updateLayout()
        
        viewModel?.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(pauseSlideShow), name: UIApplication.willResignActiveNotification, object: nil)
        
        if let viewModel = viewModel, viewModel.photos.isNotEmpty {
            playOrPauseSlideShow()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
            AppearanceManager.forceToolbarUpdate(bottomToolbar, traitCollection: traitCollection)
            statusBarBackground.backgroundColor = backgroundColor
            navigationBar.backgroundColor = backgroundColor
        }
    }
    
    func update(viewModel: SlideShowViewModel) {
        self.viewModel = viewModel
    }
    
    func executeCommand(_ command: SlideShowViewModel.Command) {
         switch command {
         case .startPlaying: play()
         case .pausePlaying: pause()
         case .initialPhotoLoaded: playOrPauseSlideShow()
         }
    }
    
    private func setVisibility(_ visible: Bool) {
        navigationBar.isHidden = !visible
        bottomToolbar.isHidden = !visible
        bottomBarBackground.isHidden = visible
        
        if !visible {
            statusBarBackground.backgroundColor = UIColor.black
        } else {
            statusBarBackground.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        }
    }
    
    private func play() {
        guard let viewModel = viewModel else { return }

        setVisibility(false)
        collectionView.backgroundColor = UIColor.black
        
        if viewModel.currentSlideNumber >= viewModel.photos.count {
            viewModel.currentSlideNumber = -1
            changeImage()
        }
        
        slideShowTimer = Timer.scheduledTimer(timeInterval: SlideShowViewModel.SlideShowAutoPlayingTimeInSeconds, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
    }
    
    private func pause() {
        setVisibility(true)
        collectionView.backgroundColor = UIColor.mnz_background()
        slideShowTimer.invalidate()
    }
    
    private func finish() {
        collectionView.backgroundColor = UIColor.mnz_background()
        slideShowTimer.invalidate()
        viewModel?.dispatch(.finishPlaying)
    }
    
    @objc private func changeImage() {
        guard let viewModel = viewModel else { return }
        
        viewModel.currentSlideNumber += 1
        if viewModel.currentSlideNumber < viewModel.photos.count {
            let index = IndexPath(item: viewModel.currentSlideNumber, section: 0)
            collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: false)
        } else {
            finish()
        }
    }
    
    @IBAction func dismissViewController() {
        viewModel?.dispatch(.finishPlaying)
        dismiss(animated: true)
    }
    
    @IBAction func playOrPauseSlideShow() {
        viewModel?.dispatch(.playOrPause)
    }
    
    @objc private func pauseSlideShow() {
        viewModel?.dispatch(.pausePlaying)
    }
}

extension SlideShowViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.8) {
            cell.alpha = 1
        }
        
        if let viewModel = viewModel, viewModel.currentSlideNumber != indexPath.row {
            viewModel.currentSlideNumber = indexPath.row
        }
        
        guard let cell = cell as? SlideShowCollectionViewCell else { return }
        cell.imageView.setToIntrinsicContentSize()
    }
}

extension SlideShowViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.numberOfSlideShowImages ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:SlideShowCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "slideShowCell", for: indexPath) as! SlideShowCollectionViewCell
        
        guard let viewModel = viewModel else { return cell }
        guard indexPath.row < viewModel.photos.count else {
            viewModel.dispatch(.finishPlaying)
            return cell
        }
        
        cell.update(withImage: viewModel.photos[indexPath.row].image, andInteraction: self)
        return cell
    }
}

extension SlideShowViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        
        if let viewModel = viewModel, let visibleIndexPath = visibleIndexPath,
            viewModel.currentSlideNumber != visibleIndexPath.row {
            viewModel.currentSlideNumber = visibleIndexPath.row
        }
    }
}

extension SlideShowViewController: SlideShowInteraction {
    func singleTapOnSlideshow() {
        viewModel?.dispatch(.pausePlaying)
    }
}
