import Foundation

class SMSCountry {
    let countryCode: String
    @objc let countryLocalizedName: String
    let countryCallingCode: String

    var displayName: String {
        return "\(countryLocalizedName) (\(displayCallingCode))"
    }

    var displayCallingCode: String {
        return "+\(countryCallingCode)"
    }

    init?(countryCode: String, countryLocalizedName: String?, callingCode: String?) {
        guard let countryLocalizedName = countryLocalizedName, let callingCode = callingCode else {
            return nil
        }

        self.countryCode = countryCode
        self.countryLocalizedName = countryLocalizedName
        self.countryCallingCode = callingCode
    }
}
