
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
    
    var rowTitles: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
        title = NSLocalizedString("Require passcode", comment: "Label indicating that the passcode (pin) view will be displayed if the application goes back to foreground after being x time in background. Examples: require passcode immediately, require passcode after 5 minutes")
        
        rowTitles = [NSLocalizedString("Immediately", comment: "Label indicating that the enter passcode (pin) view will be displayed immediately if the application goes back to foreground after being in background.")]
        rowTitles.append(NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.FiveSeconds.rawValue))
        rowTitles.append(NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.TenSeconds.rawValue))
        rowTitles.append(NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.ThirtySeconds.rawValue))
        rowTitles.append(NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.OneMinute.rawValue))
        rowTitles.append(NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.TwoMinutes.rawValue))
        rowTitles.append(NSString.mnz_string(fromCallDuration: RequirePasscodeAfter.FiveMinutes.rawValue))
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowTitles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        cell.textLabel?.textColor = UIColor.mnz_black333333()
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cell.textLabel?.text = rowTitles[indexPath.row]
        
        let timeDuration = LTHPasscodeViewController.timerDuration()
        
        if let requirePasscode: RequirePasscodeCells = RequirePasscodeCells(rawValue: indexPath.row) {
            switch requirePasscode {
            case .Immediatelly:
                cell.accessoryType = (Int(timeDuration) == RequirePasscodeAfter.Immediatelly.rawValue) ? .checkmark : .none
            case .AfterFiveSeconds:
                cell.accessoryType = (Int(timeDuration) == RequirePasscodeAfter.FiveSeconds.rawValue) ? .checkmark : .none
            case .AfterTenSeconds:
                cell.accessoryType = (Int(timeDuration) == RequirePasscodeAfter.TenSeconds.rawValue) ? .checkmark : .none
            case .AfterThirtySeconds:
                cell.accessoryType = (Int(timeDuration) == RequirePasscodeAfter.ThirtySeconds.rawValue) ? .checkmark : .none
            case .AfterOneMinute:
                cell.accessoryType = (Int(timeDuration) == RequirePasscodeAfter.OneMinute.rawValue) ? .checkmark : .none
            case .AfterTwoMinutes:
                cell.accessoryType = (Int(timeDuration) == RequirePasscodeAfter.TwoMinutes.rawValue) ? .checkmark : .none
            case .AfterFiveMinutes:
                cell.accessoryType = (Int(timeDuration) == RequirePasscodeAfter.FiveMinutes.rawValue) ? .checkmark : .none
            }
        }
        
        if cell.accessoryType == .checkmark {
            cell.accessoryView = UIImageView.init(image: UIImage.init(named: "red_checkmark"))
        } else {
            cell.accessoryView = nil
        }

        return cell
    }
    
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let requirePasscode: RequirePasscodeCells = RequirePasscodeCells(rawValue: indexPath.row) {
            switch requirePasscode {
            case .Immediatelly:
                LTHPasscodeViewController.saveTimerDuration(TimeInterval(RequirePasscodeAfter.Immediatelly.rawValue))
            case .AfterFiveSeconds:
                LTHPasscodeViewController.saveTimerDuration(TimeInterval(RequirePasscodeAfter.FiveSeconds.rawValue))
            case .AfterTenSeconds:
                LTHPasscodeViewController.saveTimerDuration(TimeInterval(RequirePasscodeAfter.TenSeconds.rawValue))
            case .AfterThirtySeconds:
                LTHPasscodeViewController.saveTimerDuration(TimeInterval(RequirePasscodeAfter.ThirtySeconds.rawValue))
            case .AfterOneMinute:
                LTHPasscodeViewController.saveTimerDuration(TimeInterval(RequirePasscodeAfter.OneMinute.rawValue))
            case .AfterTwoMinutes:
                LTHPasscodeViewController.saveTimerDuration(TimeInterval(RequirePasscodeAfter.TwoMinutes.rawValue))
            case .AfterFiveMinutes:
                LTHPasscodeViewController.saveTimerDuration(TimeInterval(RequirePasscodeAfter.FiveMinutes.rawValue))
            }
        }
        tableView.reloadData()
    }

}
