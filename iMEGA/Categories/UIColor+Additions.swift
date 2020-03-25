
import Foundation

extension UIColor {
    
    // MARK: - PRO account colors
    
    /**
    The color hex value is #FFA500
     
    - Returns: The color associated with the PRO LITE trademark.
    */
    @objc class func mnz_proLITE() -> UIColor {
        return UIColor.init(red: 1.0, green: 165.0/255.0, blue: 0.0, alpha: 1.0)
    }
    
    /**
    The color hex value is #E13339
     
    - Returns: The color associated with the PRO I trademark.
    */
    @objc class func mnz_redProI() -> UIColor {
        return UIColor.init(red: 225.0/255.0, green: 51.0/255.0, blue: 57.0/255.0, alpha: 1.0)
    }
    
    /**
    The color hex value is #DC191F
     
    - Returns: The color associated with the PRO II trademark.
    */
    @objc class func mnz_redProII() -> UIColor {
        return UIColor.init(red: 220.0/255.0, green: 25.0/255.0, blue: 31.0/255.0, alpha: 1.0)
    }
    
    /**
    The color hex value is #D90007
     
    - Returns: The color associated with the PRO III trademark.
    */
    @objc class func mnz_redProIII() -> UIColor {
        return UIColor.init(red: 217.0/255.0, green: 0, blue: 7.0/255.0, alpha: 1.0)
    }
    
    @objc class func mnz_color(proLevel : MEGAAccountType) -> UIColor? {
        var proLevelColor: UIColor?
        switch (proLevel) {
        case MEGAAccountType.free:
            proLevelColor = UIColor.mnz_green31B500()
            
        case MEGAAccountType.lite:
            proLevelColor = UIColor.mnz_proLITE()
            
        case MEGAAccountType.proI:
            proLevelColor = mnz_redProI()
            
        case MEGAAccountType.proII:
            proLevelColor = mnz_redProII()
            
        case MEGAAccountType.proIII:
            proLevelColor = mnz_redProIII()
            
        default:
            proLevelColor = nil
        }
        
        return proLevelColor
    }
    
    @objc class func mnz_colorForPriceLabel(proLevel : MEGAAccountType, traitCollection :UITraitCollection) -> UIColor? {
        var proLevelColor: UIColor?
        switch (proLevel) {
        case MEGAAccountType.free:
            proLevelColor = UIColor.mnz_green31B500()
            
        case MEGAAccountType.lite:
            proLevelColor = UIColor.mnz_proLITE()
            
        case MEGAAccountType.proI, MEGAAccountType.proII, MEGAAccountType.proIII:
            proLevelColor = UIColor.mnz_redMain(for: traitCollection)
            
        default:
            proLevelColor = nil
        }
        
        return proLevelColor
    }
}


