

extension MEGAPhotoBrowserViewController {
    @objc func subtitle(fromDate date: Date) -> String {
        DateFormatter.fromTemplate("MMMM dd • HH:mm").localisedString(from: date)
    }
    
    @objc func reloadPhotoFavouritesIfNeeded(forNodes nodes: [MEGANode]) {
        nodes.updatePhotoFavouritesIfNeeded()
    }
    
    @objc func freeUpSpace(onImageViewCache cache: NSCache<NSNumber, UIScrollView>, scrollView: UIScrollView) {
        SVProgressHUD.show()
        scrollView.subviews.forEach({ $0.removeFromSuperview() })
        cache.removeAllObjects()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SVProgressHUD.dismiss()
        }
    }
}
