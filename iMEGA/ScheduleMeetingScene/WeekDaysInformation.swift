
struct WeekDaysInformation {
    // Symbols starts with week day as Monday
    let symbols: [String] = Calendar.current.weekdaySymbols.shifted(1)
    let shortSymbols: [String] = Calendar.current.shortWeekdaySymbols.shifted(1)
    
    // Week day starts with Monday and index starts with 0
    func weekDay(forStartDate startDate: Date) -> Int {
        let index = ((Calendar.current.component(.weekday, from: startDate) - Calendar.current.firstWeekday + 7) % 7)
        return index == -1 ? 6 : index // Sunday - 6
    }
}
