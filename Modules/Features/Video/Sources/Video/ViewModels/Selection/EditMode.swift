public enum EditMode {
    case inactive
    case active
    
    public var isEditing: Bool {
        self == .active
    }
}
