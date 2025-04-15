import MEGAAppPresentation
import MEGADesignToken

extension MainTabBarController {
    var bottomConstant: CGFloat {
        tabBar.isHidden ? -view.safeAreaInsets.bottom : -tabBar.frame.size.height
    }
    
    // MARK: - Overlay Management
    @objc func setupBottomOverlayIfNeeded() {
        createBottomOverlayContainerIfNeeded()
        createBottomOverlayStackIfNeeded()
    }
    
    func addSubviewToOverlay(
        _ view: UIView,
        type: BottomSubViewType,
        priority: BottomOverlayViewPriority,
        height: CGFloat? = nil
    ) {
        setupBottomOverlayIfNeeded()
        createBottomOverlayManagerIfNeeded()
        
        bottomOverlayManager?.remove(type)
        
        let item = BottomOverlayItem(
            type: type,
            view: view,
            priority: priority,
            height: height
        )
        
        bottomOverlayManager?.add(item: item)
        
        bottomOverlayContainer?.isHidden = false
        bottomOverlayStack?.isHidden = false
        
        rebuildBottomOverlayStack()
    }
    
    func removeSubviewFromOverlay(_ type: BottomSubViewType) {
        bottomOverlayManager?.remove(type)
        rebuildBottomOverlayStack()
    }
    
    func rebuildBottomOverlayStack() {
        guard let manager = bottomOverlayManager,
              let stack = bottomOverlayStack else {
            return
        }
        
        let sortedItems = manager.sortedItems()
        
        for subview in stack.arrangedSubviews {
            stack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        for item in sortedItems {
            stack.addArrangedSubview(item.view)
            
            item.view.translatesAutoresizingMaskIntoConstraints = false
            
            if let height = item.height {
                NSLayoutConstraint.activate([
                    item.view.heightAnchor.constraint(equalToConstant: height)
                ])
            }
        }
    }
    
    // MARK: - View Updates
    func updateBottomContainerVisibility(for viewController: UIViewController) {
        let isMiniPlayerVisible = updateMiniPlayerVisibility(for: viewController)
        let isPSABannerVisible = updatePSABannerVisibility(for: viewController)
        
        if !isMiniPlayerVisible && !isPSABannerVisible, let presenter = viewController as? (any BottomOverlayPresenterProtocol) {
            presenter.updateContentView(0)
        }
    }
    
    func updatePresenterContentView() {
        guard let presenter = (selectedViewController as? UINavigationController)?.viewControllers.last as? (any BottomOverlayPresenterProtocol) else { return }
        presenter.updateContentView(bottomOverlayContainer?.frame.height ?? 0)
    }
    
    func performAnimation(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            animations()
        }, completion: { [weak self] _ in
            self?.updatePresenterContentView()
        })
    }
    
    func currentContainerHeight() -> CGFloat {
        bottomOverlayContainer?.frame.height ?? 0
    }
    
    @objc func refreshBottomConstraint() {
        guard let container = bottomOverlayContainer else { return }
        bottomContainerBottomConstraint?.constant = bottomConstant
        container.layoutIfNeeded()
    }
    
    // MARK: - Safe Area Cover Management
    
    /// Adds a cover view over the safe area when the tabBar is not present. This prevents screen content from appearing below the bottom overlay.
    func addSafeAreaCoverView() {
        guard safeAreaCoverView == nil else { return }
        
        let coverView = UIView()
        coverView.backgroundColor = TokenColors.Background.surface1
        coverView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coverView)
        
        NSLayoutConstraint.activate([
            coverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coverView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            coverView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        safeAreaCoverView = coverView
    }
    
    func removeSafeAreaCoverView() {
        guard safeAreaCoverView != nil else { return }
        
        safeAreaCoverView?.removeFromSuperview()
        safeAreaCoverView = nil
    }
    
    // MARK: - Private Helpers
    private func createBottomOverlayContainerIfNeeded() {
        guard bottomOverlayContainer == nil else { return }
        
        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        
        let bottomConstraint = container.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: bottomConstant
        )
        bottomConstraint.isActive = true
        bottomContainerBottomConstraint = bottomConstraint
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        bottomOverlayContainer = container
    }
    
    private func createBottomOverlayStackIfNeeded() {
        guard bottomOverlayStack == nil else { return }
        guard let container = bottomOverlayContainer else { return }
        
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 0
        
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        bottomOverlayStack = stack
    }
    
    private func createBottomOverlayManagerIfNeeded() {
        guard bottomOverlayManager == nil else {
            return
        }
        
        bottomOverlayManager = BottomOverlayManager()
    }
}
