import UIKit

final class PlaylistItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!

    var item: AudioPlayerItem?
    
    override var isSelected: Bool {
        didSet {
            setEditControlImage()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setEditControlImage()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        thumbnailImageView.image = nil
    }
    
    // MARK: - Private functions
    private func setSelectionImage() {
        guard let editControlClass = NSClassFromString("UITableViewCellEditControl") else { return }
        
        let imageView = subviews.first(where: { $0.isMember(of: editControlClass) })?.subviews.first(where: { $0.isKind(of: UIImageView.self)}) as? UIImageView
        imageView?.image = isSelected ? UIImage(named: "checkBoxSelected") : UIImage(named: "checkBoxUnselected")
    }

    private func setEditControlImage() {
        guard let tableViewCellEditControlClass = NSClassFromString("UITableViewCellEditControl") else { return }
        
        subviews
            .filter { $0.isMember(of: tableViewCellEditControlClass) }
            .forEach {
                let img = $0.subviews.filter { $0.isKind(of: UIImageView.self) }.first as? UIImageView
                img?.image = isSelected ? UIImage(named: "checkBoxSelected") : UIImage(named: "checkBoxUnselected")
            }
    }
    
    // MARK: - Public functions
    func configure(item: AudioPlayerItem?) {
        self.item = item
        
        titleLabel.text = item?.name
        artistLabel.text = item?.artist ?? ""
        
        if let image = item?.artwork {
            thumbnailImageView.image = image
        } else {
            thumbnailImageView.image = UIImage(named: "defaultArtwork")
        }
        
        thumbnailImageView.layer.cornerRadius = 8.0
    }
}
