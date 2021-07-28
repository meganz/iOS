
protocol DynamicTypeProtocol where Self: UIView {
    func observeContentSizeUpdates()
    func removeObserver()
    func applyFontSizes()
}

extension DynamicTypeProtocol {
    func observeContentSizeUpdates() {
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.applyFontSizes()
        }
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
