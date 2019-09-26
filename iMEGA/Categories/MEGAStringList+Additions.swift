
extension MEGAStringList {
    var stringArray: [String] {
        return (0..<size).map { string(at: $0) }
    }
    
    var first: String? {
        return size > 0 ? string(at: 0) : nil
    }
}
