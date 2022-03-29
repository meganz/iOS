
@objc enum BannerType: Int {
    case warning = 0
    
    var bgColor: UIColor {
        switch self {
        case .warning: return UIColor.mnz_yellowFED429()
        }
    }
    
    var darkBgColor: UIColor {
        switch self {
        case .warning: return UIColor.mnz_Brown544b27()
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .warning: return UIColor.mnz_yellow9D8319()
        }
    }
    
    var darkTextColor: UIColor {
        switch self {
        case .warning: return UIColor.mnz_yellowF8D552()
        }
    }
    
    var actionIcon: UIImage? {
        switch self {
        case .warning: return Asset.Images.Banner.closeCircle.image
        }
    }
}
