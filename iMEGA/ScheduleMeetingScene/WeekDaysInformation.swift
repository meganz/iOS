
struct WeekDaysInformation {
    // Symbols starts with week day as Monday
    let symbols: [String] = Calendar.current.weekdaySymbols.shifted(1)
    let shortSymbols: [String] = Calendar.current.shortWeekdaySymbols.shifted(1)
    
    // Week day starts with Monday and index starts with 0
    func weekDay(forStartDate startDate: Date) -> Int {
        let calendar = Calendar.current
        let weekDaySymbol = calendar.weekdaySymbols[calendar.component(.weekday, from: startDate) - 1]
        return symbols.firstIndex(of: weekDaySymbol) ?? 0
    }
}
