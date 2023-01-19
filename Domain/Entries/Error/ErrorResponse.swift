import SwiftyJSON

class ErrorResponse {
    var message: String
    
    required init?(message: String) {
        self.message = message
    }
}
