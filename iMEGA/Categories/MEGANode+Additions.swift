
extension MEGANode {
    open override func isEqual(_ object: Any?) -> Bool {
        guard let otherObject = object as? MEGANode else {
            return false
        }
        
        return handle == otherObject.handle
    }
}
