import Foundation

public class TimeUtils {
    
    static let TIME_FORMAT_UTC: String = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
    
    static func convertUtcToDmy(_ inputDate: String) -> String? {
        // create dateFormatter with UTC time format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        guard let date = dateFormatter.date(from: inputDate) else {
            return nil
        }
        // change to a readable time format and change to local time zone
        dateFormatter.dateFormat = LanguageHelper.language == .japanese ? "yyyy-MM-dd" : "dd-MM-yyyy"
        dateFormatter.timeZone = NSTimeZone.local
        dateFormatter.locale = Locale(identifier: LanguageHelper.language.identifier)
        let timeStamp = dateFormatter.string(from: date)
        
        return timeStamp
    }
    
    static func getDayDuration(_ startDate: String, _ endDate: String) -> Int {
        // create dateFormatter with UTC time format
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        guard let start = dateFormatter.date(from: startDate) else {
            return 0
        }
        
        guard let end = dateFormatter.date(from: endDate) else {
            return 0
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        
        return components.day ?? 0
    }
    
    static func getTimeDuration(_ startDate: String, _ endDate: String) -> String? {
        // create dateFormatter with UTC time format
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        guard let start = dateFormatter.date(from: startDate) else {
            return nil
        }
        
        guard let end = dateFormatter.date(from: endDate) else {
            return nil
        }
        // change to a readable time format and change to local time zone
        dateFormatter.dateFormat = LanguageHelper.language == .japanese ? "yy/MM/dd" : "dd/MM/yy"
        dateFormatter.timeZone = NSTimeZone.local
        
        let timeStart = dateFormatter.string(from: start)
        let timeEnd = dateFormatter.string(from: end)

        //\(timeStart) đến \(timeEnd)"
        return String(format: "FORMAT_START_TO_END_TIME".localized(), timeStart, timeEnd)
    }
    
    static func getTimeRemain(_ endDate: String) -> Int {
        // create dateFormatter with UTC time format
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        guard let end = dateFormatter.date(from: endDate) else { return 0 }

        let dateNow = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: dateNow, to: end)
        
        return components.day ?? 0
    }
    
    static func getDateFromString(_ input: String) -> Date? {
        // create dateFormatter with UTC time format
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        guard let date = dateFormatter.date(from: input) else { return nil }
        return date
    }
    
    // Check if string date inputted is expired now or not
    // True means expired
    // False mean dose not expired
    static func isExpiredNow(_ input: String) -> Bool {
        // create dateFormatter with UTC time format
        let date = getDateFromString(input)
        guard let it = date else { return true }
        
        let dateNow = Date()
        
        if it < dateNow {
            return true
        } else {
            return false
        }
    }
    
    static func convertDateToStr(
        _ date: Date,
        _ format: String = "MMM, d y"
    ) -> String {
        let fomatter = DateFormatter()
        fomatter.dateFormat = format
        fomatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return fomatter.string(from: date)
    }
}

extension Date {
    
    func getElapsedInterval() -> String {
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: Date())
        
        if let year = interval.year, year > 0 {
            return year == 1 ? String(format: "ONE_YEAR".localized(), year) :
                String(format: "YEARS".localized(), year)
        } else if let month = interval.month, month > 0 {
            return month == 1 ? String(format: "ONE_MONTH".localized(), month) :
                String(format: "MONTHS".localized(), month)
        } else if let day = interval.day, day > 0 {
            return day == 1 ? String(format: "ONE_DAY".localized(), day) :
                String(format: "DAYS".localized(), day)
        } else if let hour = interval.hour, hour > 0 {
            return hour == 1 ? String(format: "ONE_HOUR".localized(), hour) :
                String(format: "HOURS".localized(), hour)
        } else if let minute = interval.minute, minute > 0 {
            return minute == 1 ? String(format: "ONE_MINUTE".localized(), minute) :
                String(format: "MINUTES".localized(), minute)
        } else if let second = interval.second, second > 0 {
            return second == 1 ? String(format: "ONE_SECOND".localized(), second) :
                String(format: "SECONDS".localized(), second)
        } else {
            return "A_MOMENT_AGO".localized()
        }
//        if let year = interval.year, year > 0 {
//            return year == 1 ? "\(year)" + " " + "year" :
//                "\(year)" + " " + "years"
//        } else if let month = interval.month, month > 0 {
//            return month == 1 ? "\(month)" + " " + "month" :
//                "\(month)" + " " + "months"
//        } else if let day = interval.day, day > 0 {
//            return day == 1 ? "\(day)" + " " + "day" :
//                "\(day)" + " " + "days"
//        } else if let hour = interval.hour, hour > 0 {
//            return hour == 1 ? "\(hour)" + " " + "hour" :
//                "\(hour)" + " " + "hours"
//        } else if let minute = interval.minute, minute > 0 {
//            return minute == 1 ? "\(minute)" + " " + "minute" :
//                "\(minute)" + " " + "minutes"
//        } else if let second = interval.second, second > 0 {
//            return second == 1 ? "\(second)" + " " + "second" :
//                "\(second)" + " " + "seconds"
//        } else {
//            return "a moment ago"
//        }
    }
}
