import Foundation

struct PageStayTimeTracker {
    private var startTime: Date?
    private var endTime: Date?
    
    var duration: Double {
        guard let end = endTime, let start = startTime else { return 0 }
        
        return end.timeIntervalSince(start)
    }
    
    mutating func start(on date: Date = Date()) {
        startTime = date
    }
    
    mutating func end(on date: Date = Date()) {
        endTime = date
    }
}
