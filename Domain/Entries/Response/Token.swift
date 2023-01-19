import Foundation
import SwiftyJSON

public class Token: BaseModel {
    var userType: Int = 0
    var token: String = ""
    var firebasePassword: String = ""
    
    override func parseJson() {
        userType = body?["userTypeFlag"].intValue ?? 0
        token = body?["loginToken"].stringValue ?? ""
        firebasePassword = body?["firebasePassword"].stringValue ?? ""
    }
}
