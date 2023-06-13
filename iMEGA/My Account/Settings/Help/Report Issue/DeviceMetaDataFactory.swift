struct DeviceMetaDataFactory {
    let bundle: Bundle
    let locale: NSLocale
    
    func make() -> DeviceMetaData {
        let getLanguage: (_ bundle: Bundle, _ locale: NSLocale) -> String = { bundle, locale in
            let languages = bundle.preferredLocalizations
            let language = locale.displayName(forKey: .identifier, value: languages.first ?? "")
            return language ?? ""
        }
        
        let currentDevice = UIDevice.current
        let deviceName = currentDevice.name
        let osVersion = "\(currentDevice.systemName) \(currentDevice.systemVersion)"
        let language = getLanguage(bundle, locale)
        let deviceMetaData = DeviceMetaData(deviceName: deviceName, osVersion: osVersion, language: language)
        return deviceMetaData
    }
}
