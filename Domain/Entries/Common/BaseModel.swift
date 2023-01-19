import Foundation
import SwiftyJSON

open class BaseModel {
    var message: String = ""
    var body: JSON? = nil
    var isInit: Bool = false

    required public init(json: JSON?, isInit: Bool = false) {
        message = json?["message"].stringValue ?? ""
        body = json?["data"]
        self.isInit = isInit
        parseJson()
    }

    /*
     - Child class implement from BaseModel should use this function
     to parse json for each params
     - In init function all data has set to body and then all params
     should get from this variable
     */
    func parseJson() {}
}
