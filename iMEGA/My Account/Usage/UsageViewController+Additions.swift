
extension UsageViewController {
     
    @objc func storageColor(traitCollection: UITraitCollection, isStorageFull: Bool, currentPage: Int) -> UIColor {
        guard currentPage == 0, isStorageFull else {
            return UIColor.mnz_turquoise(for: traitCollection)
        }
        return UIColor.mnz_red(for: traitCollection)
    }
}
