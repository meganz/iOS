
extension MEGAStringList {
    
    var stringArray: [String] {
        var strings = [String]()
        strings.reserveCapacity(size)
        for i in 0..<size {
            strings.append(string(at: i))
        }
        
        return strings
    }
}
