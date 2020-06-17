
extension TimeInterval {
    func timeDisplayString() -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = (self >= 3600) ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self)
    }
}
