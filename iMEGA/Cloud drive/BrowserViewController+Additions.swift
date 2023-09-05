import MEGAL10n
import MEGAUIKit

extension BrowserViewController {
    
    private
    func formattedShareType(from shareType: MEGAShareType) -> String {
        
        switch shareType {
        case .accessRead:
            return Strings.Localizable.readOnly
        case .accessReadWrite:
            return Strings.Localizable.readAndWrite
        case .accessFull:
            return Strings.Localizable.fullAccess
        default:
            return ""
        }
    }
    
    private
    func updateTitle(title: String, shouldPlaceInTitleView: Bool) {
        if shouldPlaceInTitleView {
            let label = UILabel().customNavigationBarLabel(
                title: parentNode.name ?? "",
                subtitle: title,
                color: UIColor.mnz_label()
            )
        
            if let titleView = navigationItem.titleView {
                label.frame = .init(
                    x: 0,
                    y: 0,
                    width: titleView.bounds.size.width,
                    height: 44
                )
            }
            navigationItem.titleView = label
        } else {
            navigationItem.title = title
        }
        navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: title)
    }
    
    private
    func navigationBarTitleConfig() -> (copy: String, renderInTitleView: Bool) {
        if isParentBrowser {
            if browserAction == .documentProvider {
                return (Strings.Localizable.cloudDrive, false)
            } else if browserAction == .newHomeUpload {
                return (Strings.Localizable.selectDestination, false)
            } else {
                // not sure what to do with this, it's not localized
                return (Strings.localized("MEGA", comment: ""), false)
            }
        } else {
            if isChildBrowserFromIncoming {
                let accessTypeString = formattedShareType(from: parentShareType)
                
                if parentNode.name != nil {
                    return (accessTypeString, true) // here is special case when we put that in titleView
                } else {
                    return ("(\(accessTypeString))", false)
                }
            } else {
                if parentNode == nil || parentNode.type == .root {
                    return (Strings.Localizable.cloudDrive, false)
                } else {
                    return (parentNode.name ?? "", false)
                }
            }
        }
    }
    
    @objc
    func setNavigationBarTitle() {
        updatePromptTitle()
        let titleConfig = navigationBarTitleConfig()
        updateTitle(title: titleConfig.copy, shouldPlaceInTitleView: titleConfig.renderInTitleView)
    }
    
    @objc func prompt(forSelectedCount count: Int) -> String {
        guard count > 0 else {
            return Strings.Localizable.selectTitle
        }
        return Strings.Localizable.General.Format.itemsSelected(count)
    }
}
