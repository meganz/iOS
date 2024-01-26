extension ThumbnailViewerTableViewCell {
    @objc func updateAppearance(with traitCollection: UITraitCollection) {
        backgroundColor = UIColor.mnz_backgroundElevated(traitCollection)
        thumbnailViewerCollectionView?.backgroundColor = UIColor.mnz_backgroundElevated(traitCollection)
        addedByLabel?.textColor = UIColor.cellTitleColor(for: traitCollection)
        timeLabel?.textColor = UIColor.mnz_subtitles(for: traitCollection)
        infoLabel?.textColor = UIColor.mnz_subtitles(for: traitCollection)
    }
}
