import DateToolsSwift

extension Date {
    func string(withDateFormat dateFormat: String) -> String {
        return MegaDataFormatter.shared.string(fromDate: self, dateFormat: dateFormat)
    }
    
    func isSameDay(date: Date) -> Bool {
        return isSame(date: date, components: [.day, .month, .year])
    }
    
    func isSameMinute(date: Date) -> Bool {
        return isSame(date: date, components: [.minute, .day, .month, .year])
    }
    
    func isSame(date: Date, components: Set<Calendar.Component>) -> Bool {
        let thisDateComponents = Calendar.current.dateComponents(components, from: self)
        let otherDateComponents = Calendar.current.dateComponents(components, from: date)
        let results = components.map { thisDateComponents.value(for: $0) == otherDateComponents.value(for: $0) }
        return !results.contains(false)
    }
}
