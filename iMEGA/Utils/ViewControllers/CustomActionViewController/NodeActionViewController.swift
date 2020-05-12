import UIKit

class NodeActionViewController: ActionSheetViewController {

    @objc var node: MEGANode?
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    func configureView() {
        headerView?.frame = CGRect(x: 0, y: 0, width: 320, height: 80)
        let imageView = UIImageView.newAutoLayout()
        imageView.mnz_setThumbnail(by: node)
        headerView?.addSubview(imageView)
        imageView.autoSetDimensions(to: CGSize(width: 40, height: 40))
        imageView.autoPinEdge(toSuperviewEdge: .leading, withInset: 8)
        imageView.autoAlignAxis(toSuperviewAxis: .horizontal)

        let title = UILabel.newAutoLayout()
        title.text = node?.name
        title.font = .systemFont(ofSize: 15)
        headerView?.addSubview(title)

        title.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: 8)
        title.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        title.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: -8)

        let subtitle = UILabel.newAutoLayout()
        subtitle.textColor = .systemGray
        subtitle.font = .systemFont(ofSize: 12)
        headerView?.addSubview(subtitle)

        subtitle.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: 8)
        subtitle.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        subtitle.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: 8)

        let separatorLine = UIView.newAutoLayout()
        separatorLine.backgroundColor = tableView.separatorColor
        headerView?.addSubview(separatorLine)

        separatorLine.autoPinEdge(toSuperviewEdge: .leading)
        separatorLine.autoPinEdge(toSuperviewEdge: .trailing)
        separatorLine.autoPinEdge(toSuperviewEdge: .bottom)
        separatorLine.autoSetDimension(.height, toSize: 1/UIScreen.main.scale)

        if node != nil {
            if node!.isFile() {
                subtitle.text = Helper.sizeAndDate(for: node!, api: MEGASdkManager.sharedMEGASdk())
            } else {
                subtitle.text = Helper.filesAndFolders(inFolderNode: node!, api: MEGASdkManager.sharedMEGASdk())
            }
        }
    }
}
