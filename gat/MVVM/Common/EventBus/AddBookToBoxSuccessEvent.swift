import Foundation

// Fired when user add book to box success in dialog AlertAddBookReadingViewController
// BookDetailContainerController handle this event to update data again
// and show dialog update progress of reading
struct AddBookToBoxSuccessEvent {
    static let EVENT_NAME = "AddBookToBoxSuccessEvent"
}
