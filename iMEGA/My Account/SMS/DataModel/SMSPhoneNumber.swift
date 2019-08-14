
struct SMSPhoneNumber {
    let country: SMSCountry
    let localNumber: String
    
    var fullPhoneNumberString: String {
        return "\(country.displayCallingCode)\(localNumber)"
    }
}
