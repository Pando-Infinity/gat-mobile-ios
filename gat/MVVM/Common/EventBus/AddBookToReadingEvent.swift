import Foundation

// Fired when user want to add any book to Reading list
// handle this event to add this Book to Reading list
struct AddBookToReadingEvent {
    static let EVENT_NAME: String = "AddBookToReadingEvent"
    
    var bookId: Int = 0
    var readingId: Int?
    var currentPage: Int = 0
    var numPage: Int = 0
    var startDate: String = ""
    var completeDate: String = ""
    var bookName: String = ""
    var readingStatusId: Int = 0
    
    init(
        _ bookId: Int,
         _ readingId: Int? = nil,
         _ currentPage: Int = 0,
         _ numPage: Int = 0,
         _ startDate: String = "",
         _ completeDate: String = "",
         bookName: String = "",
         readingStatusId: Int 
    ) {
        self.bookId = bookId
        self.readingId = readingId
        self.currentPage = currentPage
        self.numPage = numPage
        self.startDate = startDate
        self.completeDate = completeDate
        self.bookName = bookName
        self.readingStatusId = readingStatusId
    }
}
