
import UIKit

enum RequirePasscodeCells: Int {
    case Immediatelly
    case AfterFiveSeconds
    case AfterTenSeconds
    case AfterThirtySeconds
    case AfterOneMinute
    case AfterTwoMinutes
    case AfterFiveMinutes
}

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
    
    var passcodeInfo: [PasscodeDurationInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
        title = NSLocalizedString("Require passcode", comment: "Label indicating that the passcode (pin) view will be displayed if the application goes back to foreground after being x time in background. Examples: require passcode immediately, require passcode after 5 minutes")
        
        passcodeInfo.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.Immediatelly.rawValue, durationTitle: NSLocalizedString("Immediately", comment: "Label indicating that the enter passcode (pin) view will be displayed immediately if the application goes back to foreground after being in background.")))
        passcodeInfo.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.FiveSeconds.rawValue, durationTitle: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.FiveSeconds.rawValue)))
        passcodeInfo.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.TenSeconds.rawValue, durationTitle: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.TenSeconds.rawValue)))
        passcodeInfo.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.ThirtySeconds.rawValue, durationTitle: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.ThirtySeconds.rawValue)))
        passcodeInfo.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.OneMinute.rawValue, durationTitle: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.OneMinute.rawValue)))
        passcodeInfo.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.TwoMinutes.rawValue, durationTitle: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.TwoMinutes.rawValue)))
        passcodeInfo.append(PasscodeDurationInfo(duration: RequirePasscodeAfter.FiveMinutes.rawValue, durationTitle: NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.FiveMinutes.rawValue)))
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return passcodeInfo.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        cell.textLabel?.textColor = UIColor.mnz_black333333()
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cell.textLabel?.text = passcodeInfo[indexPath.row].durationTitle
        
        let timerDuration = LTHPasscodeViewController.timerDuration()
        
        if Int(timerDuration) == passcodeInfo[indexPath.row].duration {
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
        LTHPasscodeViewController.saveTimerDuration(TimeInterval(passcodeInfo[indexPath.row].duration))
        tableView.reloadData()
    }

}
