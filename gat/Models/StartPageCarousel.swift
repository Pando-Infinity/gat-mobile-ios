//
//  StartPageCarousel.swift
//  gat
//
//  Created by HungTran on 4/14/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RealmSwift

/** Lưu dữ liệu slider carousel lúc bắt đầu app*/
class StartPageCarousel: Object {
    /** Mã phân biệt*/
    @objc dynamic var id: Int = -1
    
    /** Ảnh của carousel*/
    @objc dynamic var image: String = ""
    /** Tiêu đề carousel*/
    @objc dynamic var title: String = ""
    /** Nội dung carousel*/
    @objc dynamic var content: String = ""
    
    /*Cài đặt khoá chính cho bảng StartPageCarousel*/
    override static func primaryKey() -> String? {
        return "id"
    }
}
