import MEGAAppSDKRepo
import MEGADesignToken

extension OnboardingViewController {
    @objc func setupTertiaryButton() {
        tertiaryButton?.titleLabel?.numberOfLines = 0
        tertiaryButton?.titleLabel?.textAlignment = .center
    }
    
    @objc func updateAppearance() {
        view.backgroundColor = TokenColors.Background.page
        scrollView?.backgroundColor = TokenColors.Background.page
        
        pageControl?.currentPageIndicatorTintColor = currentPageIndicatorColor()
        pageControl?.pageIndicatorTintColor = pageIndicatorColor()
        pageControl?.backgroundColor = TokenColors.Background.page
        
        primaryButton?.mnz_setupPrimary()
        secondaryButton?.mnz_setupSecondary()
        tertiaryButton?.mnz_setupSecondary()
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
