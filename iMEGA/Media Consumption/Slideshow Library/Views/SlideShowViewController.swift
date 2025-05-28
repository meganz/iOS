import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import UIKit

protocol SlideShowInteraction: AnyObject {
    func pausePlaying()
}

final class SlideShowViewController: UIViewController, ViewType {
    private let viewModel: SlideShowViewModel

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

    init?(coder: NSCoder, viewModel: SlideShowViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("You must create this view controller with a viewModel.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        slideShowOptionButton.title = Strings.Localizable.Slideshow.PreferenceSetting.options
        collectionView.updateLayout()
        setUpBoundsChangeHandler()
        setupViewModel()
        adjustHeightOfTopAndBottomView()
        setVisibility(false)
        setNavigationAndToolbarColor()
        setupActivityIndicator()

        viewModel.dispatch(.onViewReady)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.dispatch(.viewDidAppear)
    }

    private func setupViewModel() {
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    private func showLoader() {
        activityIndicator.color = MEGAAssets.UIColor.whiteFFFFFF
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
    }

    private func hideLoader() {
        activityIndicator.stopAnimating()
        view.sendSubviewToBack(activityIndicator)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.dispatch(.onViewWillDisappear)
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            adjustHeightOfTopAndBottomView()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        CrashlyticsLogger.log("[SlideShow] Device orientation is landscape: \(UIDevice.current.orientation.isLandscape)")
    }

    private func setNavigationAndToolbarColor() {
        bottomBarBackground.backgroundColor = TokenColors.Background.surface1
        statusBarBackground.backgroundColor = TokenColors.Background.surface1
        btnPlay.tintColor = TokenColors.Icon.primary
        slideShowOptionButton.tintColor = TokenColors.Icon.primary
    }
    
    private func adjustHeightOfTopAndBottomView() {
        let safeArea = UIApplication.shared.keyWindow?.safeAreaInsets
        let topHeight = safeArea?.top ?? .zero
        let bottomHeight = safeArea?.bottom ?? .zero

        if statusBarBackgroundViewHeightConstraint.constant != topHeight {
            statusBarBackgroundViewHeightConstraint.constant = topHeight
        }

        if bottomBarBackgroundViewHeightConstraint.constant != bottomHeight {
            bottomBarBackgroundViewHeightConstraint.constant = bottomHeight
        }
    }

    @MainActor
    func executeCommand(_ command: SlideShowViewModel.Command) {
         switch command {
         case .adjustHeightOfTopAndBottomViews: adjustHeightOfTopAndBottomView()
         case .play: play()
         case .pause: pause()
         case .initialPhotoLoaded: handleInitialPhotoLoaded()
         case .hideLoader: hideLoader()
         case .resetTimer: resetTimer()
         case .restart: restart()
         case .showLoader: showLoader()
         }
    }

    private func handleInitialPhotoLoaded() {
        // The 0.01 delay is needed for the collection view to layout its content properly before we can scroll
        // to the photo at `viewModel.currentSlideIndex`. Without this delay, collectionView.scrollToItem(...)
        // won't work correctly and flakily fault (aka scrolls to wrong position or does not scroll at all).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [self] in
            collectionView.scrollToItem(at: .init(item: viewModel.currentSlideIndex, section: 0), at: .centeredHorizontally, animated: false)
            playSlideShow()
        }
    }

    private func setVisibility(_ visible: Bool) {
        navigationBar.alpha = visible ? 1 : 0
        bottomToolbar.alpha = visible ? 1 : 0
        bottomBarBackground.alpha = visible ? 1 : 0
        statusBarBackground.alpha = visible ? 1 : 0
    }
    
    private func play() {
        let cell = collectionView.visibleCells.first(where: { $0 is SlideShowCollectionViewCell }) as? SlideShowCollectionViewCell
        setVisibility(false)
        CrashlyticsLogger.log("[SlideShow] play button tapped.")
        let currentIndex = viewModel.currentSlideIndex
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
        self.collectionView.backgroundColor = .black
        self.view.backgroundColor = TokenColors.Background.page
        cell?.resetZoomScale()
        resetTimer()
    }
    private func pause() {
        CrashlyticsLogger.log("[SlideShow] paused.")
        hideLoader()
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
        viewModel.dispatch(.finish)
    }

    private func resetTimer() {
        CrashlyticsLogger.log("[SlideShow] Timer reset.")
        slideShowTimer.invalidate()
        slideShowTimer = Timer.scheduledTimer(timeInterval: viewModel.timeIntervalForSlideInSeconds, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func restart() {
        CrashlyticsLogger.log("[SlideShow] restarted.")
        hideLoader()
        reload()
        collectionView.scrollToItem(at: IndexPath(item: viewModel.currentSlideIndex, section: 0), at: .left, animated: false)
        play()
    }

    private func scrollToItem(index: Int, animate: Bool) {
        guard animate else {
            let indexPath = IndexPath(row: index, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            return
        }
        let duration = 1.0
        let currentContentOffsetX = collectionView.contentOffset.x

        let steps = 60
        let delay = duration / Double(steps)
        let currentVerticalSizeClass = traitCollection.verticalSizeClass
        let currentHorizontalSizeClass = traitCollection.horizontalSizeClass

        func animateTransition(to step: Int = 1, totalSteps: Int) {

            guard step <= totalSteps else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                if currentVerticalSizeClass != traitCollection.verticalSizeClass || currentHorizontalSizeClass != traitCollection.horizontalSizeClass {
                    // When orientation changes, we stop the animation
                    // The collectionView's boundsChangeHandler will take care of the orientation changes
                    return
                }

                let itemWidth = self.collectionView.bounds.size.width
                let targetContentOffset = Double(index) * itemWidth

                let distance = targetContentOffset - currentContentOffsetX
                let progress = Double(step) / Double(steps)
                let xOffset: Double = distance * progress
                self.collectionView.contentOffset = CGPoint(x: currentContentOffsetX + xOffset, y: 0)

                animateTransition(to: step + 1, totalSteps: totalSteps)
            }
        }
        animateTransition(totalSteps: steps)
    }

    @objc private func changeImage() {
        let slideNumber = viewModel.currentSlideIndex + 1

        if slideNumber < numberOfSlideShowContents() {
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
        // The reason we don't animate on 0 index items is because,
        // when it loops back to the start, we don't get a scrolling through cells animation.
        let animate = viewModel.currentSlideIndex != 0
        scrollToItem(index: viewModel.currentSlideIndex, animate: animate)
    }
    
    @IBAction func dismissViewController() {
        finish()
        dismiss(animated: true)
    }
    
    @IBAction func slideShowOptionTapped(_ sender: Any) {
        SlideShowOptionRouter(
            presenter: self,
            preference: viewModel,
            currentConfiguration: viewModel.configuration
        ).start()
    }
    
    @IBAction func playSlideShow() {
        viewModel.dispatch(.play)
    }
    
    private func reload() {
        collectionView?.reloadData()
    }

    private func setUpBoundsChangeHandler() {
        collectionView.boundsChangeHandler = { [weak self] in
            guard let self else { return }
            // After the bounds changes, we need to wait for the collection view to layout first before
            // processing further, hence the 0.01 delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self else { return }
                let wasPlaying = viewModel.playbackStatus == .playing
                let currentIndex = viewModel.currentSlideIndex
                let indexPath = IndexPath(item: currentIndex, section: 0)

                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.layoutIfNeeded()

                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                // For some unknown reasons `collectionView.scrollToItem()` won't work and contentOffset.x is zero,
                // In that case we need to update collectionView.contentOffset explicitly
                if collectionView.contentOffset.x == 0 {
                    self.collectionView.contentOffset = CGPoint(x: collectionView.bounds.size.width * Double(currentIndex), y: 0)
                }

                DispatchQueue.main.async {
                    if wasPlaying {
                        self.play()
                    }
                }
            }
        }
    }
}

extension SlideShowViewController: UICollectionViewDataSource {
    
    private func numberOfSlideShowContents() -> Int {
        viewModel.numberOfSlideShowContents
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfSlideShowContents()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SlideShowCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "slideShowCell", for: indexPath) as! SlideShowCollectionViewCell
        guard let mediaEntity = viewModel.mediaEntity(at: indexPath) else { return cell }
        cell.update(with: mediaEntity, andInteraction: self)
        return cell
    }
}

extension SlideShowViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        
        if let visibleIndexPath = visibleIndexPath,
            viewModel.currentSlideIndex != visibleIndexPath.row {
            CrashlyticsLogger.log("[SlideShow] scrollview interupption: - current slide is changed from \(viewModel.currentSlideIndex) to \(visibleIndexPath.row)")
            viewModel.currentSlideIndex = visibleIndexPath.row
        }
        
        if viewModel.playbackStatus == .playing {
            viewModel.dispatch(.resetTimer)
        }
    }
}

extension SlideShowViewController: SlideShowInteraction {
    func pausePlaying() {
        viewModel.dispatch(.pause)
    }
}
