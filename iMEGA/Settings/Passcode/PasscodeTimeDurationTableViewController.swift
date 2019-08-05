
import UIKit

@objc enum RequirePasscodeAfter: Int {
    case Immediatelly = -1
    case FiveSeconds = 5
    case TenSeconds = 10
    case ThirtySeconds = 30
    case OneMinute = 60
    case TwoMinutes = 120
    case FiveMinutes = 300
}

@objc class PasscodeTimeDurationTableViewController: UITableViewController {
    
    private let cellReuseId = "tableViewCellId"
    
    var passcodeDurationInfoArray: [PasscodeDurationInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
        title = NSLocalizedString("Require passcode", comment: "Label indicating that the passcode (pin) view will be displayed if the application goes back to foreground after being x time in background. Examples: require passcode immediately, require passcode after 5 minutes")
        
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.Immediatelly.rawValue, title: NSLocalizedString("Immediately", comment: "Label indicating that the enter passcode (pin) view will be displayed immediately if the application goes back to foreground after being in background.")))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.FiveSeconds.rawValue, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.FiveSeconds.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.TenSeconds.rawValue, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.TenSeconds.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.ThirtySeconds.rawValue, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.ThirtySeconds.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.OneMinute.rawValue, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.OneMinute.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.TwoMinutes.rawValue, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.TwoMinutes.rawValue)))
        passcodeDurationInfoArray.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.FiveMinutes.rawValue, title: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.FiveMinutes.rawValue)))
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return passcodeDurationInfoArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        cell.textLabel?.textColor = UIColor.mnz_black333333()
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cell.textLabel?.text = passcodeDurationInfoArray[indexPath.row].title
        
        let timerDuration = LTHPasscodeViewController.timerDuration()
        
        if Int(timerDuration) == passcodeDurationInfoArray[indexPath.row].duration {
            cell.accessoryType = .checkmark
            cell.accessoryView = UIImageView.init(image: UIImage.init(named: "red_checkmark"))
        } else {
            cell.accessoryType = .none
            cell.accessoryView = nil
        }

        return cell
    }
    
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        LTHPasscodeViewController.saveTimerDuration(TimeInterval(passcodeDurationInfoArray[indexPath.row].duration))
        tableView.reloadData()
    }

}
