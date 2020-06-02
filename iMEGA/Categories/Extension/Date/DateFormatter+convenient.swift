//
//  DateFormatter+convenient.swift
//  MEGA
//
//  Created by Jun Meng on 2/6/20.
//  Copyright © 2020 MEGA. All rights reserved.
//

import Foundation

extension DateFormatter {

    // MARK: - Date Formatter

    /// Monday Jun 1, 2020
    static let dateMediumWithWeekday = DateFormatterPool.shared.dateFormatter(of: .dateMediumWithWeekday)
    /// Jun 1, 2020
    static let dateMedium = DateFormatterPool.shared.dateFormatter(of: .dateMedium)

    // MARK: - Relative date formatter, e.g. date in the next day will be "Tomorrow" etc.

    /// Jun 1, 2020 or "Tomorrow", "Today", "Yesterday"
    static let dateMediumRelative = DateFormatterPool.shared.dateFormatter(of: .dateMediumRelative)
}
