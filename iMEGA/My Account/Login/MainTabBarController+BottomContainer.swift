extension MainTabBarController {
    var bottomConstant: CGFloat {
        tabBar.isHidden ? -view.safeAreaInsets.bottom : -tabBar.frame.size.height
    }
    
    @objc func setupBottomOverlayIfNeeded() {
        createBottomOverlayContainerIfNeeded()
        createBottomOverlayStackIfNeeded()
    }
    
    func addSubviewToOverlay(
        _ view: UIView,
        type: BottomSubViewType,
        priority: BottomOverlayViewPriority,
        height: CGFloat
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
        view.isHidden = false
        
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
            NSLayoutConstraint.activate([
                item.view.heightAnchor.constraint(equalToConstant: item.height)
            ])
        }
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
