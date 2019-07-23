
struct PhoneNumber {
    let callingCountry: CallingCountry
    let localNumber: String
    
    var fullPhoneNumber: String {
        return "\(callingCountry.displayCallingCode)\(localNumber)"
    }
}
