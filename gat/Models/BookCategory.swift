//
//  BookCategory.swift
//  gat
//
//  Created by HungTran on 4/14/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

/** Lưu dữ liệu category của sách để làm cho chức năng chọn category
 yêu thích ngay lúc người dùng vừa đăng ký & chọn địa điểm thành công*/
class BookCategory: Object {
    /** Mã phân biệt - Khoá chính*/
    @objc dynamic var id: Int = -1
    
    /** Ảnh category*/
    @objc dynamic var image: String = ""
    
    /** Tên category*/
    @objc dynamic var name: String = ""
    
    /*Mức độ ưu tiên*/
    @objc dynamic var priority: Int = 0
    
    /** Trạng thái lựa chọn ban đầu*/
    @objc dynamic var selected: Bool = false
    
    /*Cài đặt khoá chính cho bảng BookCategory*/
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func create(id: Int, name: String) -> BookCategory {
        let category = BookCategory()
        category.id = id
        category.name = name
        return category
    }
    
    /**Trả về đối tượng BookCategory từ JSON*/
    static func parseFrom(json: JSON) -> BookCategory? {
        guard let id = json["categoryId"].int else {
            return nil
        }
        if let category = try! Realm().object(ofType: BookCategory.self, forPrimaryKey: id) {
            try! Realm().safeWrite {
                if json["image"].exists(), let image = json["image"].string {
                    category.image = image
                }
                if json["name"].exists(), let name = json["name"].string {
                    category.name = name
                }
                if json["priority"].exists(), let priority = json["priority"].int {
                    category.priority = priority
                }
                if json["selected"].exists(), let selected = json["selected"].bool {
                    category.selected = selected
                }
            }
            return category
        } else {
            let category = BookCategory()
            category.id = id
            category.image = json["image"].string ?? ""
            category.name = json["name"].string ?? ""
            category.selected = json["selected"].bool ?? false
            category.priority = json["priority"].int ?? 0
            return category
        }
    }
}
