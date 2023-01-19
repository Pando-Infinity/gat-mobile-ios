import Foundation

struct OpenBookDetailEvent {
    static let EVENT_NAME = "OpenBookDetailEvent"
    
    var bookInfo: BookInfo?
    
    init(_ bookInfo: BookInfo) {
        self.bookInfo = bookInfo
    }
}
