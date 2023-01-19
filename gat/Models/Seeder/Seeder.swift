//
//  ModelSeeder.swift
//  gat
//
//  Created by HungTran on 3/20/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import Fakery
import RealmSwift

/*Tất cả dữ liệu seed để test cho các bảng nằm hết tại đây
Hàm tạo dữ liệu seed sẽ được gọi trong App Delegate*/
class Seeder {
    
    /**Cài đặt mẫu SingleTon*/
    static let shared = Seeder()
    let realm = try? Realm()
    let faker = Faker(locale: "vi-VN")
    
    func seed() {
        
        // Đăng ký dữ liệu category (Fix sẵn)
        self.seedDataBookCategory()
        
        // Đẩy dữ liệu Carousel
        self.seedDataStartPageCarousel()
    }
}
