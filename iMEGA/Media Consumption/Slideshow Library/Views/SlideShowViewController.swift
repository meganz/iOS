import MEGADesignToken
import MEGAL10n
import MEGAPresentation
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
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var slideShowTimer = Timer()
    
    private var backgroundColor: UIColor {
        UIColor.surface1Background()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        slideShowOptionButton.title = Strings.Localizable.Slideshow.PreferenceSetting.options
        collectionView.updateLayout()

        NotificationCenter.default.addObserver(self, selector: #selector(pauseSlideShow), name: UIApplication.willResignActiveNotification, object: nil)
        
        adjustHeightOfTopAndBottomView()
        setVisibility(false)
        setNavigationAndToolbarColor()
        setupActivityIndicator()
        guard let viewModel = viewModel else {
            showLoader()
            return
        }
        if viewModel.photos.isNotEmpty {
            playSlideShow()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.dispatch(.viewDidAppear)
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    private func showLoader() {
        activityIndicator.color = UIColor.whiteFFFFFF
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func hideLoader() {
        activityIndicator.stopAnimating()
        view.sendSubviewToBack(activityIndicator)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            collectionView.collectionViewLayout.invalidateLayout()
            reload()
            updateSlideInView()
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
       
        CrashlyticsLogger.log("[SlideShow] Device orientation is landscape: \(UIDevice.current.orientation.isLandscape)")
    }
    
    private func setNavigationAndToolbarColor() {
        AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
        AppearanceManager.forceToolbarUpdate(bottomToolbar, traitCollection: traitCollection)
        bottomBarBackground.backgroundColor = UIColor.surface1Background()
        statusBarBackground.backgroundColor = UIColor.surface1Background()
    }
    
    private func adjustHeightOfTopAndBottomView() {
        let safeArea = UIApplication.shared.keyWindow?.safeAreaInsets
        statusBarBackgroundViewHeightConstraint.constant = safeArea?.top ?? .zero
        bottomBarBackgroundViewHeightConstraint.constant = safeArea?.bottom ?? .zero
    }
    
    func update(viewModel: SlideShowViewModel) {
        self.viewModel = viewModel
        self.viewModel?.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        hideLoader()
        if viewModel.photos.isNotEmpty {
            reload()
            playSlideShow()
        }
    }
    
    func executeCommand(_ command: SlideShowViewModel.Command) {
         switch command {
         case .play: play()
         case .pause: pause()
         case .initialPhotoLoaded: playSlideShow()
         case .resetTimer: resetTimer()
         case .restart: restart()
         case .showLoader: showLoader()
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
        
        CrashlyticsLogger.log("[SlideShow] play button tapped.")
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.collectionView.backgroundColor = .black000000
            self.view.backgroundColor = TokenColors.Background.page
            cell?.resetZoomScale()
            if viewModel.currentSlideIndex >= viewModel.photos.count - 1 {
                viewModel.currentSlideIndex = -1
                self.changeImage()
            }
        }
        resetTimer()
    }
    
    private func pause() {
        CrashlyticsLogger.log("[SlideShow] paused.")

        setVisibility(true)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.collectionView.backgroundColor = UIColor.systemBackground
            self.view.backgroundColor = self.backgroundColor
        }
        slideShowTimer.invalidate()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func finish() {
        collectionView.backgroundColor = UIColor.systemBackground
        slideShowTimer.invalidate()
        hideLoader()
        viewModel?.dispatch(.finish)
    }
    
    private func resetTimer() {
        guard let viewModel = viewModel else { return }
        CrashlyticsLogger.log("[SlideShow] Timer reset.")
        
        slideShowTimer.invalidate()
        slideShowTimer = Timer.scheduledTimer(timeInterval: viewModel.timeIntervalForSlideInSeconds, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func restart() {
        guard let viewModel = viewModel else { return }
        CrashlyticsLogger.log("[SlideShow] restarted.")
        hideLoader()
        reload()
        collectionView.scrollToItem(at: IndexPath(item: viewModel.currentSlideIndex, section: 0), at: .left, animated: false)
        play()
    }
    
    @objc private func changeImage() {
        guard let viewModel = viewModel else { return }
        
        let slideNumber = viewModel.currentSlideIndex + 1
        
        if slideNumber < viewModel.photos.count {
            CrashlyticsLogger.log("[SlideShow] current slide is changed from \(viewModel.currentSlideIndex) to \(slideNumber)")
            viewModel.currentSlideIndex = slideNumber
            hideLoader()
            updateSlideInView()
        } else if viewModel.configuration.isRepeat {
            CrashlyticsLogger.log("[SlideShow] current slide is changed from \(viewModel.currentSlideIndex) to 0")
            viewModel.currentSlideIndex = 0
            hideLoader()
            updateSlideInView()
        } else if slideNumber >= viewModel.numberOfSlideShowContents {
           hideLoader()
           finish()
        } else {
            showLoader()
        }
    }
    
    private func updateSlideInView() {
        guard let viewModel = viewModel else { return }
        
        let index = IndexPath(item: viewModel.currentSlideIndex, section: 0)
        if collectionView.isValid(indexPath: index) {
            collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: false)
        }
    }
    
    @IBAction func dismissViewController() {
        finish()
        dismiss(animated: true)
    }
    
    @IBAction func slideShowOptionTapped(_ sender: Any) {
        guard let viewModel else { return }
        SlideShowOptionRouter(
            presenter: self,
            preference: viewModel,
            currentConfiguration: viewModel.configuration
        ).start()
    }
    
    @IBAction func playSlideShow() {
        viewModel?.dispatch(.play)
    }
    
    @objc private func pauseSlideShow() {
        viewModel?.dispatch(.pause)
        hideLoader()
    }
    
    private func reload() {
        collectionView?.reloadData()
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
        viewModel?.numberOfSlideShowContents ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SlideShowCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "slideShowCell", for: indexPath) as! SlideShowCollectionViewCell
        
        guard let viewModel = viewModel, let mediaEntity = viewModel.mediaEntity(at: indexPath) else { return cell }
        cell.update(with: mediaEntity, andInteraction: self)
        return cell
    }
}

extension SlideShowViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        
        if let viewModel = viewModel, let visibleIndexPath = visibleIndexPath,
            viewModel.currentSlideIndex != visibleIndexPath.row {
            CrashlyticsLogger.log("[SlideShow] scrollview interupption: - current slide is changed from \(viewModel.currentSlideIndex) to \(visibleIndexPath.row)")
            viewModel.currentSlideIndex = visibleIndexPath.row
        }
        
        if viewModel?.playbackStatus == .playing {
            viewModel?.dispatch(.resetTimer)
        }
    }
}

extension SlideShowViewController: SlideShowInteraction {
    func pausePlaying() {
        viewModel?.dispatch(.pause)
        hideLoader()
    }
}
