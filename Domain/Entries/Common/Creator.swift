import SwiftyJSON

public class Creator {
    var id: Int = 0
    var name: String = ""
    var imageId: String = ""
    var address: String = ""
    var userTypeFlag: Int = 0
    var coverImageId: String = ""
    var about: String = ""
    var latitude: Double = 0.0
    var longtitude: Double = 0.0
    
    init(fromJson json: JSON?) {
        id = json?["userId"].intValue ?? 0
        name = json?["name"].stringValue ?? ""
        imageId = json?["imageId"].stringValue ?? ""
        address = json?["address"].stringValue ?? ""
        userTypeFlag = json?["userTypeFlag"].intValue ?? 0
        coverImageId = json?["coverImageId"].stringValue ?? ""
        about = json?["about"].stringValue ?? ""
        latitude = json?["latitude"].double ?? 0.0
        longtitude = json?["longitude"].double ?? 0.0
    }
}
