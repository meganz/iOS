import UIKit
import MEGADomain

@objc protocol TransferActionViewControllerDelegate: NodeActionViewControllerDelegate {
   @objc optional func transferAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for transfer: MEGATransfer, from sender: Any) ->  ()
}

class TransferActionViewController: NodeActionViewController {

    @objc var transfer: MEGATransfer?
    override func viewDidLoad() {
        super.viewDidLoad()

        if let transfer = transfer, transfer.type == .upload {
            configureTransferHeaderView()
        }
    }
    

    func configureTransferHeaderView() {
        guard let transfer = transfer else {
            return
        }
        let pathExtension = (transfer.fileName as NSString).pathExtension
        nodeImageView.image = NodeAssetsManager.shared.image(for: pathExtension)
        titleLabel.text = transfer.fileName
        switch transfer.state {
        case .cancelled:
            subtitleLabel.text = Strings.Localizable.cancelled
        case .failed:
            let transferFailed = Strings.Localizable.transferFailed
            guard let error = transfer.lastErrorExtended, let errorString = MEGAError.errorStringWithErrorCode(error.type.rawValue, context: .upload) else {
                return
            }
            subtitleLabel.text = "\(transferFailed) \(NSLocalizedString(errorString, comment: ""))"

        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        guard let action = actions[indexPath.row] as? NodeAction, let delegate = delegate as? TransferActionViewControllerDelegate, let transfer = transfer else {
            return
        }
        
        delegate.transferAction?(self, didSelect: action.type, for: transfer, from: sender)
    }
}
