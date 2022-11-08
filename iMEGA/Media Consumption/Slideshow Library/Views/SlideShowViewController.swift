import UIKit

protocol SlideShowInteraction {
    func pausePlaying()
}

final class SlideShowViewController: UIViewController, ViewType {
    private var viewModel: SlideShowViewModel?
    
    @IBOutlet var collectionView: SlideShowCollectionView!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var bottomToolbar: UIToolbar!
    @IBOutlet var statusBarBackground: UIView!
    @IBOutlet var bottomBarBackground: UIView!
    @IBOutlet var btnPlay: UIBarButtonItem!
    @IBOutlet weak var bottomBarBackgroundViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusBarBackgroundViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var slideShowOptionButton: UIBarButtonItem!
    
    private var slideShowTimer = Timer()
    
    private var backgroundColor: UIColor {
        UIColor.mnz_mainBars(for: traitCollection)
    }
    
    private func updatePlayButtonTintColor() {
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            btnPlay.tintColor = UIColor.mnz_gray515151()
            slideShowOptionButton.tintColor = UIColor.mnz_gray515151()
        case .dark:
            btnPlay.tintColor = UIColor.mnz_grayD1D1D1()
            slideShowOptionButton.tintColor = UIColor.mnz_grayD1D1D1()
        @unknown default:
            btnPlay.tintColor = UIColor.mnz_gray515151()
            slideShowOptionButton.tintColor = UIColor.mnz_gray515151()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        slideShowOptionButton.title = Strings.Localizable.Slideshow.PreferenceSetting.options
        collectionView.updateLayout()
        viewModel?.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(pauseSlideShow), name: UIApplication.willResignActiveNotification, object: nil)
        
        if let viewModel = viewModel, viewModel.photos.isNotEmpty {
            playSlideShow()
        }
        
        adjustHeightOfTopAndBottomView()
        setVisibility(false)
        setNavigationAndToolbarColor()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            self?.updateSlideInView()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setNavigationAndToolbarColor()
        }
        
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            adjustHeightOfTopAndBottomView()
        }
    }
    
    private func setNavigationAndToolbarColor() {
        AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
        AppearanceManager.forceToolbarUpdate(bottomToolbar, traitCollection: traitCollection)
        bottomBarBackground.backgroundColor = bottomToolbar.backgroundColor
        statusBarBackground.backgroundColor = bottomToolbar.backgroundColor
        updatePlayButtonTintColor()
    }
    
    private func adjustHeightOfTopAndBottomView() {
        let safeArea = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets
        statusBarBackgroundViewHeightConstraint.constant = safeArea?.top ?? .zero
        bottomBarBackgroundViewHeightConstraint.constant = safeArea?.bottom ?? .zero
    }
    
    func update(viewModel: SlideShowViewModel) {
        self.viewModel = viewModel
    }
    
    func executeCommand(_ command: SlideShowViewModel.Command) {
         switch command {
         case .play: play()
         case .pause: pause()
         case .initialPhotoLoaded: playSlideShow()
         case .resetTimer: resetTimer()
         case .restart: restart()
         }
    }
    
    private func setVisibility(_ visible: Bool) {
        navigationBar.alpha = visible ? 1 : 0
        bottomToolbar.alpha = visible ? 1 : 0
        bottomBarBackground.alpha = visible ? 1 : 0
        statusBarBackground.alpha = visible ? 1 : 0
    }
    
    private func play() {
        guard let viewModel = viewModel else { return }
        let cell = collectionView.visibleCells.first(where: { $0 is SlideShowCollectionViewCell }) as? SlideShowCollectionViewCell
        setVisibility(false)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.collectionView.backgroundColor = UIColor.black
            self.view.backgroundColor = .black
            cell?.resetZoomScale()
            if viewModel.currentSlideNumber >= viewModel.photos.count {
                viewModel.currentSlideNumber = -1
                self.changeImage()
            }
        }
        resetTimer()
    }
    
    private func pause() {
        setVisibility(true)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.collectionView.backgroundColor = UIColor.mnz_background()
            self.view.backgroundColor = self.backgroundColor
        }
        slideShowTimer.invalidate()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func finish() {
        collectionView.backgroundColor = UIColor.mnz_background()
        slideShowTimer.invalidate()
        viewModel?.dispatch(.finish)
    }
    
    private func resetTimer() {
        guard let viewModel = viewModel else { return }
        
        slideShowTimer.invalidate()
        slideShowTimer = Timer.scheduledTimer(timeInterval: viewModel.timeIntervalForSlideInSeconds, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func restart() {
        guard let viewModel = viewModel else { return }
        
        collectionView.reloadData()
        collectionView.scrollToItem(at: IndexPath(item: viewModel.currentSlideNumber, section: 0), at: .left, animated: false)
        play()
    }
    
    @objc private func changeImage() {
        guard let viewModel = viewModel else { return }
        
        viewModel.currentSlideNumber += 1
        if viewModel.currentSlideNumber < viewModel.photos.count {
            updateSlideInView()
        } else if viewModel.configuration.isRepeat {
            viewModel.currentSlideNumber = 0
            updateSlideInView()
        } else {
            finish()
        }
    }
    
    private func updateSlideInView() {
        guard let viewModel = viewModel else { return }
        
        let index = IndexPath(item: viewModel.currentSlideNumber, section: 0)
        if collectionView.isValid(indexPath: index) {
            collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: false)
        }
    }
    
    @IBAction func dismissViewController() {
        viewModel?.dispatch(.finish)
        dismiss(animated: true)
    }
    
    @IBAction func slideShowOptionTapped(_ sender: Any) {
        if #available(iOS 14.0, *) {
            guard let viewModel = viewModel else { return }
            SlideShowOptionRouter(
                presenter: self,
                preference: viewModel,
                currentConfiguration: viewModel.configuration
            ).start()
        }
    }
    
    @IBAction func playSlideShow() {
        viewModel?.dispatch(.play)
    }
    
    @objc private func pauseSlideShow() {
        viewModel?.dispatch(.pause)
    }
}

extension SlideShowViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.8) {
            cell.alpha = 1
        }
        
        guard let cell = cell as? SlideShowCollectionViewCell else { return }
        cell.resetZoomScale()
    }
}

extension SlideShowViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.numberOfSlideShowContents ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:SlideShowCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "slideShowCell", for: indexPath) as! SlideShowCollectionViewCell
        
        guard let viewModel = viewModel else { return cell }
        guard indexPath.row < viewModel.photos.count,
                let image = viewModel.photos[indexPath.row].image
        else {
            viewModel.dispatch(.finish)
            return cell
        }
        
        cell.update(withImage: image, andInteraction: self)
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
        
        if viewModel?.playbackStatus == .playing {
            viewModel?.dispatch(.resetTimer)
        }
    }
}

extension SlideShowViewController: SlideShowInteraction {
    func pausePlaying() {
        viewModel?.dispatch(.pause)
    }
}
