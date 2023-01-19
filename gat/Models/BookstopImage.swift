//
//  BookstopImage.swift
//  gat
//
//  Created by Vũ Kiên on 10/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import SwiftyJSON
import RealmSwift

public class BookstopImage {
    var url: String = ""
    var caption: String = ""
    
    init(url: String, caption: String) {
        self.url = url
        self.caption = caption
    }
    
    init() {
        
    }
    
    static func parse(json: JSON) -> [BookstopImage] {
        return json["images"].string?.components(separatedBy: ",").map({ (imageId) -> BookstopImage in
            return BookstopImage(url: AppConfig.sharedConfig.setUrlImage(id: imageId, size: .m), caption: "")
        }) ?? []
    }
}

extension BookstopImage: ObjectConvertable {
    typealias Object = BookstopImageObject
    
    func asObject() -> BookstopImageObject {
        let object = BookstopImageObject()
        object.url = self.url
        object.caption = self.caption
        return object
    }
    
}

class BookstopImageObject: Object {
    @objc dynamic var url: String = ""
    @objc dynamic var caption: String = ""
}

extension BookstopImageObject: DomainConvertable {
    typealias Domain = BookstopImage
    
    func asDomain() -> BookstopImage {
        let domain = BookstopImage()
        domain.url = self.url
        domain.caption = self.caption
        return domain
    }
}
