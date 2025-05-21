import MediaPlayer
import MEGAAssets
import MEGADomain
import UIKit

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
    
    var disabled: Bool = false {
        didSet {
            updateUI()
        }
    }
    
    private func updateUI() {
        guard let properties = properties else {
            return
        }
        
        circularView.backgroundColor = !disabled && isSelected ? properties.backgroundColor.selected : properties.backgroundColor.normal
        iconImageView.tintColor = !disabled && isSelected ? properties.iconTintColor.selected : disabled ? properties.iconTintColor.normal.withAlphaComponent(0.25) : properties.iconTintColor.normal
    }
}

final class MeetingSpeakerQuickActionView: MeetingQuickActionView {
        
    func selectedAudioPortUpdated(_ selectedAudioPort: AudioPort, isBluetoothRouteAvailable: Bool) {
        switch selectedAudioPort {
        case .builtInReceiver:
            iconImageView.image = MEGAAssets.UIImage.callControlSpeakerDisabled
            isSelected = false
        case .builtInSpeaker, .headphones:
            iconImageView.image = MEGAAssets.UIImage.callControlSpeakerEnabled
            isSelected = true
        default:
            if isBluetoothRouteAvailable {
                iconImageView.image = MEGAAssets.UIImage.audioSourceMeetingAction
                isSelected = true
            } else {
                iconImageView.image = MEGAAssets.UIImage.callControlSpeakerDisabled
                isSelected = false
            }
        }
    }

    func addRoutingView() {
        guard subviews.notContains(where: { $0 is AVRoutePickerView }) else {
            return
        }
        
        let routerPickerView = AVRoutePickerView()
        routerPickerView.tintColor = .clear
        routerPickerView.activeTintColor = .clear
        wrap(routerPickerView)
    }
    
    func removeRoutingView() {
        guard let routePickerView = subviews.first(where: { $0 is AVRoutePickerView }) as? AVRoutePickerView else {
            return
        }
        
        routePickerView.removeFromSuperview()
    }
}
