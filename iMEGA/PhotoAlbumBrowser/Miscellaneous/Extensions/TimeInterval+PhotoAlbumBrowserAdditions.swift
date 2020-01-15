
extension TimeInterval {
    var timeDisplayString: String {
        let timeInt = Int(self)
        let seconds = timeInt % 60
        let minutes = (timeInt / 60) % 60
        let hours = (timeInt / 3600)
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return String(format:"00:%02d", seconds)
        }
    }
}
