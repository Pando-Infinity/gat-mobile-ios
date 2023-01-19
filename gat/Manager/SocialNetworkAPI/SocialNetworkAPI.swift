//
//  SocialAPI.swift
//  gat
//
//  Created by HungTran on 2/25/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RxSwift

/**Định nghĩa các lỗi có thể có (Thông báo, Offline, UnAuthorized)*/
enum HTError: Error {
    /**Lỗi chung chung, chỉ mang tính chất thông báo*/
    case General(String)
    /**Lỗi không có mạng*/
    case Offline(String)
    /**Lỗi không có thẩm quyền (401)*/
    case Unauthorized(String)
    /**Lỗi dữ liệu đã bị thay đổi bởi người dùng khác (409)*/
    case OldData(String)
    /**Lỗi chỉ hiển thị ở Log*/
    case Silent(String)
}

/**Định nghĩa kiểu trả về cho tất cả các API của cả GaT và SocialNetworkAPI*/
enum Result<Value> {
    /**Giá trị thành công có thể là bất cứ kiểu gì.
    Sử dụng Generic thay cho AnyObject để tận dụng tính năng Suggest kiểu của Xcode*/
    case Success(Value)
    /**Các lỗi khiến tiến trình thất bại luôn là dạng thông điệp*/
    case Failure(HTError)
}

/**Định nghĩa kiểu dữ liệu SocialPublicData - Lưu trữ dữ liệu Public của User trên các mạng xã hội*/
typealias SocialPublicData = (id: String, type: SocialNetworkType, name: String, email: String, image: Data, authId: String, secretToken: String)

/**Khai báo các SocialNetwork và Map code tương ứng với từng Network
 
 None = 0, Không phải mạng xã hội
 Facebook = 1
 Google = 2
 Twitter = 3*/
enum SocialNetworkType:Int {
    case None = 0 // Không phải mạng xã hội nào hết
    case Facebook = 1
    case Google = 2
    case Twitter = 3
}

/**Khu vực khai báo Protocol chung cho tất cả các SocialNetwork*/
protocol SocialNetworkAPI {
    
    /**Lấy token đăng nhập của tài khoản mạng xã hội*/
    func getAuthToken() -> Observable<Result<(String,String)>>
    
    /**Lấy một số public data cần thiết để thực hiện phần đăng ký tài khoản
    Các data đó bao gồm: id+, type+, name+, email, imageUrl. (+) nghĩa là bắt buộc*/
    func getPublicData() -> Observable<Result<SocialPublicData>>
}

/**SocialNetwork[Default]API
Cài đặt mẫu Strategy để tận dụng được 3 lợi ích
+ Vừa dùng được các method được quy định trong SocialNetworkAPI Protocol
+ Có thể linh động thay đổi các implement của các method tuỳ vào tình huống sau này*/
class SocialNetworkDefaultAPI {
    
    /**Thuộc tính lưu lại implement của Network*/
    public var socialNetworkAPI: SocialNetworkAPI
    
    /**Khởi tạo SocialNetworkAPI với một API tuỳ thuộc vào tình huống cụ thể*/
    init(socialNetwork: SocialNetworkAPI) {
        self.socialNetworkAPI = socialNetwork
    }
    
    /**Lấy token đăng nhập của tài khoản mạng xã hội*/
    func getAuthToken() -> Observable<Result<(String,String)>> {
        return socialNetworkAPI.getAuthToken()
    }
    
    /**Lấy một số public data cần thiết để thực hiện phần đăng ký tài khoản
    Các data đó bao gồm: id+, type+, name+, email, imageUrl. (+) nghĩa là bắt buộc*/
    func getPublicData() -> Observable<Result<SocialPublicData>> {
        return socialNetworkAPI.getPublicData()
    }
    
}
