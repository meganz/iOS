/// Enum which maps an appropiate symbol which added as prefix for each log message
///
/// - error: Log type error
/// - info: Log type info
/// - debug: Log type debug
/// - verbose: Log type verbose
/// - warning: Log type warning
/// - severe: Log type severe
private enum LogType: String {
    case e = "[‼️]" // error
    case i = "[ℹ️]" // info
    case d = "[💬]" // debug
    case v = "[🔬]" // verbose
    case w = "[⚠️]" // warning
    case s = "[🔥]" // severe
}

internal extension Date {
    func toString() -> String {
        return LogManager.dateFormatter.string(from: self as Date)
    }
}

class LogManager {
    
    // MARK: - Properties
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    private static var dateFormat = "hh:mm:ss"
    private static var isLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Public Functions
extension LogManager {
    
    /// Logs error messages on console with prefix [‼️]
    ///
    /// - Parameters:
    ///   - object: Object or message to be logged
    ///   - filename: File name from where loggin to be done
    ///   - line: Line number in file from where the logging is done
    ///   - column: Column number of the log message
    ///   - funcName: Name of the function from where the logging is done
    class func e( _ object: Any, filename: String = #file, line: Int = #line, funcName: String = #function) {
        if isLoggingEnabled {
            print("LogManager: \(Date().toString()) \(LogType.e.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(funcName) -> \(object)")
        }
    }
    
    /// Logs info messages on console with prefix [ℹ️]
    ///
    /// - Parameters:
    ///   - object: Object or message to be logged
    ///   - filename: File name from where loggin to be done
    ///   - line: Line number in file from where the logging is done
    ///   - column: Column number of the log message
    ///   - funcName: Name of the function from where the logging is done
    class func i( _ object: Any, filename: String = #file, line: Int = #line, funcName: String = #function) {
        if isLoggingEnabled {
            print("LogManager: \(Date().toString()) \(LogType.i.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(funcName) -> \(object)")
        }
    }
    
    /// Logs debug messages on console with prefix [💬]
    ///
    /// - Parameters:
    ///   - object: Object or message to be logged
    ///   - filename: File name from where loggin to be done
    ///   - line: Line number in file from where the logging is done
    ///   - column: Column number of the log message
    ///   - funcName: Name of the function from where the logging is done
    class func d( _ object: Any, filename: String = #file, line: Int = #line, funcName: String = #function) {
        if isLoggingEnabled {
            print("LogManager: \(Date().toString()) \(LogType.d.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(funcName) -> \(object)")
        }
    }
    
    /// Logs messages verbosely on console with prefix [🔬]
    ///
    /// - Parameters:
    ///   - object: Object or message to be logged
    ///   - filename: File name from where loggin to be done
    ///   - line: Line number in file from where the logging is done
    ///   - column: Column number of the log message
    ///   - funcName: Name of the function from where the logging is done
    class func v( _ object: Any, filename: String = #file, line: Int = #line, funcName: String = #function) {
        if isLoggingEnabled {
            print("LogManager: \(Date().toString()) \(LogType.v.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(funcName) -> \(object)")
        }
    }
    
    /// Logs warnings verbosely on console with prefix [⚠️]
    ///
    /// - Parameters:
    ///   - object: Object or message to be logged
    ///   - filename: File name from where loggin to be done
    ///   - line: Line number in file from where the logging is done
    ///   - column: Column number of the log message
    ///   - funcName: Name of the function from where the logging is done
    class func w( _ object: Any?, filename: String = #file, line: Int = #line, funcName: String = #function) {
        if isLoggingEnabled {
            print("LogManager: \(Date().toString()) \(LogType.w.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(funcName) -> \(object!)")
        }
    }
    
    /// Logs severe events on console with prefix [🔥]
    ///
    /// - Parameters:
    ///   - object: Object or message to be logged
    ///   - filename: File name from where loggin to be done
    ///   - line: Line number in file from where the logging is done
    ///   - column: Column number of the log message
    ///   - funcName: Name of the function from where the logging is done
    class func s( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if isLoggingEnabled {
            print("LogManager: \(Date().toString()) \(LogType.s.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)")
        }
    }
    
    class func req(_ request: RequestModel) {
        guard isLoggingEnabled else { return }
        
        let path: String = request.path
        let headers: String = String(describing: request.headers)
        let httpMethod: String = String(describing: request.method.rawValue)
        var body: String = ""
        var bodyStrings: [String] = []
        for item in request.body {
            if let value = item.value {
                bodyStrings.append("\(item.key): \(type(of: value))(\(value))")
            } else {
                bodyStrings.append("\(item.key): nil")
            }
        }
        body = bodyStrings.joined(separator: ", ")
        
        var log: String = "[\(ServiceManager.shared.BASE_URL)\(path)]"
        
        if !request.headers.isEmpty {
            log += "\n\(headers)"
        }
        
        log += "\n[\(httpMethod)]"
        
        if !request.body.isEmpty {
            log += "\n[\(body)]"
        }
        
        print("LogManager: \n--- Request ---\n[\(Date().toString())] \n\(log) \n--- End ---\n")
    }
    
    class func res<T: Decodable>(_ response: ResponseModel<T>) {
        guard isLoggingEnabled else { return }
        
        let path: String? = response.request?.path
        let isSuccess: Bool = response.meta?.status == 200
        let message: String = response.meta?.msg ?? ""
        let dataJSON: String? = response.json
        
        var log: String = ""
        
        if let path = path {
            log += "[\(ServiceManager.shared.BASE_URL)\(path)]\n"
        }
        
        log += "[isSuccess: \(isSuccess)]\n[message: \(message)]"
        
        if let json = dataJSON {
            log += "\n[\(json)]"
        }
        
        print("LogManager: \n--- Response ---\n[\(Date().toString())] \n\(log) \n--- End ---\n")
    }
    
    class func err(_ error: ErrorModel) {
        guard isLoggingEnabled else { return }
        
        let errorKey: String? = error.messageKey
        
        var log: String = ""
        
        if let errorKey = errorKey {
            log += "\n[key: \(errorKey)]"
        }
        
        if log.isEmpty { return }
        
        print("LogManager: \n--- Error ---\n[\(Date().toString())] \(log) \n--- End ---\n")
    }
}

// MARK: - Private Functions
private extension LogManager {
    
    /// Extract the file name from the file path
    ///
    /// - Parameter filePath: Full file path in bundle
    /// - Returns: File Name with extension
    class func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}
