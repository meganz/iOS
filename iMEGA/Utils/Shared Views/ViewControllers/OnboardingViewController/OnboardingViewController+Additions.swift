import MEGADesignToken
import MEGASDKRepo

extension OnboardingViewController {
    @objc func setupTertiaryButton() {
        tertiaryButton?.titleLabel?.numberOfLines = 0
        tertiaryButton?.titleLabel?.textAlignment = .center
    }
    
    @objc func updateAppearance() {
        view.backgroundColor = UIColor.pageBackgroundColor(for: traitCollection)
        scrollView?.backgroundColor = UIColor.pageBackgroundColor(for: traitCollection)
        
        pageControl?.currentPageIndicatorTintColor = currentPageIndicatorColor()
        pageControl?.pageIndicatorTintColor = pageIndicatorColor()
        pageControl?.backgroundColor = UIColor.pageBackgroundColor(for: traitCollection)
        
        primaryButton?.mnz_setupPrimary(traitCollection)
        secondaryButton?.mnz_setupSecondary(traitCollection)
        
        if UIColor.isDesignTokenEnabled() {
            tertiaryButton?.mnz_setupSecondary(traitCollection)
        } else {
            tertiaryButton?.setTitleColor(UIColor.mnz_turquoise(for: traitCollection), for: .normal)
        }
    }
    
    // MARK: - Private
    
    private func currentPageIndicatorColor() -> UIColor {
        if UIColor.isDesignTokenEnabled() {
            TokenColors.Background.surface3
        } else {
            UIColor.mnz_turquoise(for: traitCollection)
        }
    }
    
    private func pageIndicatorColor() -> UIColor {
        if UIColor.isDesignTokenEnabled() {
            if traitCollection.userInterfaceStyle == .dark {
                TokenColors.Background.surface1
            } else {
                TokenColors.Background.surface2
            }
        } else {
            UIColor.mnz_tertiaryGray(for: traitCollection)
        }
    }
}
