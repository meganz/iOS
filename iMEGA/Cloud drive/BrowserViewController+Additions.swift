import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import MEGAUIKit

extension BrowserViewController {
    
    @objc func makeViewModel() -> BrowserViewModel {
        BrowserViewModel(
            parentNode: parentNode,
            isChildBrowser: isChildBrowser,
            isSelectVideos: browserAction == .selectVideo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo))
    }
    
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
            let label = UILabel.customNavigationBarLabel(title: parentNode.name ?? "", subtitle: title, traitCollection: traitCollection)
        
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

    @objc func setCellBackgroundColor(_ cell: NodeTableViewCell) {
        if UIColor.isDesignTokenEnabled() {
            cell.backgroundColor = TokenColors.Background.page
        }
    }

    @objc func updateAppearance() {
        if UIColor.isDesignTokenEnabled() {
            view.backgroundColor = TokenColors.Background.page
        } else {
            view.backgroundColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection)
        }

        updateSelector()
    }

    @objc func updateSelector() {
        if UIColor.isDesignTokenEnabled() {
            selectorView.backgroundColor = TokenColors.Background.surface1
        } else {
            selectorView.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        }

        updateButtonAndLineView(for: cloudDriveButton, with: cloudDriveLineView)
        updateButtonAndLineView(for: incomingButton, with: incomingLineView)
    }

    private func updateButtonAndLineView(for button: UIButton, with lineView: UIView) {
        // Fonts are not supported by `MEGADesignToken`, so the FF shouldn't influence them
        let footnotePointSize = UIFont.preferredFont(forTextStyle: .footnote).pointSize
        let fontWeight = button.isSelected ? UIFont.Weight.semibold : UIFont.Weight.medium
        button.titleLabel?.font = UIFont.systemFont(ofSize: footnotePointSize, weight: fontWeight)

        if UIColor.isDesignTokenEnabled() {
            button.setTitleColor(TokenColors.Icon.secondary, for: .normal)
            button.setTitleColor(TokenColors.Button.brand, for: .selected)
            lineView.backgroundColor = button.isSelected ? TokenColors.Button.brand : TokenColors.Border.strong
        } else {
            button.setTitleColor(UIColor.mnz_primaryGray(for: traitCollection), for: .normal)
            button.setTitleColor(UIColor.mnz_red(for: traitCollection), for: .selected)
            lineView.backgroundColor = button.isSelected ? UIColor.mnz_red(for: traitCollection) : nil
        }
    }
    
    @objc func handleAddNodes(isReachableHUDIfNot: Bool) {
        guard isReachableHUDIfNot, selectedNodesMutableDictionary.count > 0 else {
            return
        }
        
        if isParentBrowser {
            attachNodes()
        } else {
            guard let browserVC = navigationController?.viewControllers.first as? BrowserViewController else {
                return
            }
            browserVC.attachNodes()
        }
    }
    
    @objc var toolBarAddBarButtonItemTitle: String {
        Strings.Localizable.Videos.Tab.Playlist.Browser.Button.add
    }
}
