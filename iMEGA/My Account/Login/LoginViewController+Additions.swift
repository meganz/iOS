import MEGASwift

extension LoginViewController {
    @objc func recoveryPasswordURL(_ email: String?) -> URL {
        let encodedEmail = email?.base64Encoded
        let recoveryURLString = encodedEmail != nil ? "https://mega.nz/recovery?email=\(encodedEmail ?? "")" : "https://mega.nz/recovery"
    
        return URL(string: recoveryURLString) ?? URL(fileURLWithPath: "")
    }
}
