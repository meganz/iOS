
import UIKit
import MediaPlayer

class MeetingQuickActionView: UIView {
    
    struct Properties {
        let iconTintColor: StateColor
        let backgroundColor: StateColor
        
        struct StateColor {
            var normal: UIColor
            var selected: UIColor
        }
    }
    
    
    
    @IBOutlet weak fileprivate var circularView: CircularView!
    @IBOutlet weak fileprivate var iconImageView: UIImageView!
    @IBOutlet weak fileprivate var nameLabel: UILabel!
    @IBOutlet weak fileprivate var button: UIButton!

    var icon: UIImage? {
        didSet {
            iconImageView.image = icon
        }
    }
    
    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }
    
    var properties: Properties? {
        didSet {
            updateUI()
        }
    }

    var isSelected: Bool = false {
        didSet {
            updateUI()
        }
    }
    
    private func updateUI() {
        guard let properties = properties else {
            return
        }
        
        circularView.backgroundColor = isSelected ? properties.backgroundColor.selected : properties.backgroundColor.normal
        iconImageView.tintColor = isSelected ? properties.iconTintColor.selected : properties.iconTintColor.normal
    }
}

final class MeetingSpeakerQuickActionView: MeetingQuickActionView {
        
    func selectedAudioPortUpdated(_ selectedAudioPort: AudioPort, isBluetoothRouteAvailable: Bool) {
        switch selectedAudioPort {
        case .builtInReceiver, .headphones, .builtInSpeaker:
            iconImageView.image = UIImage(named: "speakerMeetingAction")
            isSelected = !(selectedAudioPort == .builtInReceiver)
        default:
            if isBluetoothRouteAvailable {
                iconImageView.image = UIImage(named: "audioSourceMeetingAction")
                isSelected = true
            } else {
                iconImageView.image = UIImage(named: "speakerMeetingAction")
                isSelected = false
            }
        }
    }

    func addRoutingView() {
        guard subviews.filter({ $0 is AVRoutePickerView }).count == 0 else {
            return
        }
        
        let routerPickerView = AVRoutePickerView()
        routerPickerView.tintColor = .clear
        routerPickerView.activeTintColor = .clear

        fillSubview(routerPickerView)
    }
    
    func removeRoutingView() {
        guard let routePickerView = subviews.filter({ $0 is AVRoutePickerView }).first as? AVRoutePickerView else {
            return
        }
        
        routePickerView.removeFromSuperview()
    }
    
    private func fillSubview(_ subview: UIView) {
        addSubview(subview)

        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.heightAnchor.constraint(equalTo: heightAnchor),
            subview.widthAnchor.constraint(equalTo: widthAnchor),
            subview.centerXAnchor.constraint(equalTo: centerXAnchor),
            subview.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
