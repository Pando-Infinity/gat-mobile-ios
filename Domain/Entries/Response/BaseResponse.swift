import Foundation
import SwiftyJSON

public class BaseResponse<T: BaseModel>: SectionDataType {
    typealias data = T
    
    var message: String = ""
    //var data: T? = nil
    
    required public init(json: JSON) {
        message = json["message"].stringValue
        //data = T(json: json["data"])
        data(json: json["data"])
        //BaseModel(json: <#T##JSON#>)
    }
}
