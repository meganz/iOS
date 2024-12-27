protocol DynamicTypeComponentProtocol where Self: UIView {
    func observeContentSizeUpdates()
    func removeObserver()
    func applyFontSizes()
}

extension DynamicTypeComponentProtocol {
    func observeContentSizeUpdates() {
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.applyFontSizes()
            }
        }
    }
    
    nonisolated func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
