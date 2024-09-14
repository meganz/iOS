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
        tertiaryButton?.mnz_setupSecondary(traitCollection)
    }
    
    // MARK: - Private
    
    private func currentPageIndicatorColor() -> UIColor {
        TokenColors.Background.surface3
    }
    
    private func pageIndicatorColor() -> UIColor {
        if traitCollection.userInterfaceStyle == .dark {
            TokenColors.Background.surface1
        } else {
            TokenColors.Background.surface2
        }
    }
}
