////
////  GaTAPI.swift
////  gat
////
////  Created by HungTran on 2/21/17.
////  Copyright © 2017 GaTBook. All rights reserved.
//import Foundation
//import RxSwift
//import Alamofire
////import AlamofireImage
//import SwiftyJSON
//import RealmSwift
//import UIKit
////import XCGLogger
//import FirebaseAnalytics
//
///**Protocol dành riêng cho GaTAPI*/
///* Todo
// + [OK] Thêm vào header tất cả các request: Accept-Language: en-US
// + [OK] API cập nhật FavoriteCategory
// + [OK] Upload ảnh
// */
//
///**o: Cỡ nguyên gốc, t: Thumbnail, s: Small, q: large*/
//enum GaTImageSize: String {
//    case o
//    case t
//    case s
//    case q
//}
//
///**Định nghĩa kiểu trả về cho API lấy list sách đang đọc của user
// 3 giá trị Int tương ứng:
// "readingTotal": 25,
// "toReadTotal": 18,
// "readTotal": 40*/
//typealias ReadingBookInstantResult = (Int, Int, Int, List<ReadingBookInstant>)
//
///**Định nghĩa kiểu trả về cho API lấy list sách đang cho mượn của user
// "sharingTotal": 10,
// "notSharingTotal": 14,
// "lostTotal" :3,*/
//typealias BorrowingBookInstantResult = (Int, Int, Int, List<BookInstant>)
//
///**Định nghĩa kiểu trả về cho API lấy list request từ/tới user
// "waitingTotal": 0,
// "sharingTotal": 10,
// "borrowingTotal": 12*/
//typealias BorrowingBookRequestResult = (Int, Int, Int, List<BorrowingBookRequest>)
//
///**Định nghĩa kiểu trả về khi Reset Password
//
// - resetToken
// - SocialNetworkType
// - socialId
// - socialName*/
//typealias ResetPasswordResult = (String, SocialNetworkType, String, String)
//
//protocol GaTAPI {
//    //MARK: - 1. User Authentication API(s)
//    /**API_U001.1: Đăng ký tài khoản bằng email*/
//    func register(email: String, name: String, password: String, isLoading: Bool) -> Observable<Result<Session>>
//
//    /**API_U001.2: Đăng ký tài khoảng bằng social*/
//    func socialNetworkRegister(socialID: String, socialType: SocialNetworkType, name: String, email: String, password: String, avatarData: UIImage, authId: String, secretToken: String, isLoading: Bool) -> Observable<Result<Session>>
//
//    /**API_U002.1: Đăng nhập tài khoản bằng email*/
//    func attempt(email: String, password: String, isLoading: Bool) -> Observable<Result<Session>>
//
//    /**API_U002.2: Đăng nhập tài khoảng bằng social*/
//    func oAuthAttempt(token: String, socialNetworkType: SocialNetworkType, authId: String, secretToken: String, isLoading: Bool) -> Observable<Result<Session>>
//
//    /**API_U002.3: Sign out*/
//    func logout(isLoading: Bool) -> Observable<Result<String>>
//
//    /**API_U003: Send yêu cầu reset pass by email (gửi token 6 chữ số về email)*/
//    func requestResetPasswordToken(email: String, isLoading: Bool) -> Observable<Result<ResetPasswordResult>>
//
//    /**API_U004: Verify reset token*/
//    func verifyResetCode(tokenResetPassword: String, code: String, isLoading: Bool) -> Observable<Result<String>>
//
//    /**API_U005: Reset password*/
//    func changePassword(tokenVerify: String, password: String, isLoading: Bool) -> Observable<Result<Session>>
//
//    //MARK: - 2. User Info API(s)
//    /**API_U006: Update user information*/
//    func updateUserInfo(name: String, Image: UIImage, changeImageFlag: Bool, isLoading: Bool) -> Observable<Result<String>>
//
//    /**API_U007: Update favourite book category*/
//    func saveFavoriteCategory(categoryList: [Int], isLoading: Bool) -> Observable<Result<String>>
//
//    /**API_U008: Update usually location*/
//    func updateUsuallyLocation(address: String, latitude: Double, longitude: Double, isLoading: Bool) -> Observable<Result<String>>
//
//    /**API_U009: Get user detail information*/
//    func getLoginUserInfo(isLoading: Bool) -> Observable<Result<User>>
//
//    /**API_U010: Get public info of other user*/
//    func getUserPublicInfo(userId: Int, isLoading: Bool) -> Observable<Result<User>>
//
//    /**API_U011: User liên kết social*/
//    func linkSocial(socialID: String, socialName: String, socialType: SocialNetworkType, isLoading: Bool) -> Observable<Result<String>>
//
//    /**API_U012: User huỷ liên kết social*/
//    func unlinkSocial(socialType: SocialNetworkType, isLoading: Bool) -> Observable<Result<String>>
//
//    /**API_U014: User thêm email và password*/
//    func addEmailPassword(email: String, password: String, isLoading: Bool) -> Observable<Result<Session>>
//
//    /**API_U015: User thay đổi mật khẩu*/
//    func updatePassword(oldPassword: String, newPassword: String, isLoading: Bool) -> Observable<Result<Session>>
//
//    /**API_U016: Firebase token register
//
//     - Đăng ký FirebaseToken lấy từ:
//     https://firebase.google.com/docs/reference/ios/firebaseinstanceid/api/reference/Classes/FIRInstanceID*/
//    func registerFirebaseToken(token: String, isLoading: Bool) ->  Observable<Result<String>>
//
//    //MARK: - 3. Reading & Book API(s)
//    /**API_R001: Lấy thông tin chi tiết về sách, bao gồm thông tin sách, tác giả, category, rate avg, sharing count…*/
//    func getBookEditionDetailBy(id: Int, isLoading: Bool) -> Observable<Result<BookEdition>>
//
//    /**API_R003: Lấy list các book instance của mình (kèm tên người mượn nếu có)*/
//    func getUserBookInstant(filterData: [String: String], page: Int, perPage: Int, isLoading: Bool) -> Observable<Result<BorrowingBookInstantResult>>
//
//    /**API_R004: Lấy list các book đang public sharing của user khác*/
//    func getPublicSharingBookEdition(ownerId: Int, userId: Int, page: Int, perPage: Int, isLoading: Bool) -> Observable<Result<(Int, List<PublicSharingBookEdition>)>>
//
//    /**API_R005: Remove book instance*/
//    func deleteUserBookInstant(instantId: Int, isLoading: Bool) -> Observable<Result<String>>
//
//    /**API_R006: Change book instance sharing status*/
//    func updateUserBookInstantStatus(instantId: Int, sharingStatus: Int, isLoading: Bool) -> Observable<Result<String>>
//
//    /**API_R008: Lấy thông tin đọc (reading info - bao gồm read, reading, to read) của user (kèm thông tin mượn từ ai - nếu có)*/
//    func getUserReadingBookInstant(userId: Int, filterData: [String: String], page: Int, perPage: Int, isLoading: Bool) -> Observable<Result<ReadingBookInstantResult>>
//
//    //MARK: - 4. Sharing & Borrowing API(s)
//    /**API_B001: Get book borrowing record/request*/
//    func getBorrowingBookRequest(filterData: [String: String], page: Int, perPage: Int, isLoading: Bool) -> Observable<Result<BorrowingBookRequestResult>>
//
//    /**API_B002: Create borrowing request*/
//    func createBorrowingRequest(ownerId: Int, editionId: Int, isLoading: Bool) -> Observable<Result<BorrowingBookRequest>>
//
//    /**API_B003A: Update status of borrowing request by owner*/
//    func updateRequestByOwner(recordId: Int, currentStatus: Int, newStatus: Int, isLoading: Bool) -> Observable<Result<(Int, Int)>>
//
//    /**API_B003B: Update status of borrowing request by borrower*/
//    func updateRequestByBorrower(recordId: Int, currentStatus: Int, newStatus: Int, isLoading: Bool) -> Observable<Result<(Int, Int)>>
//
//    /**API_B004: Get detail information of request*/
//    func getBorrowingRequestDetail(recordId: Int, isLoading: Bool) -> Observable<Result<BorrowingBookRequest>>
//
//    //MARK: - 5. Searching API(s)
//    /**API_S002: Search book by isbn Result is one book*/
//    func getBookEditionIdBy(isbn: String, isLoading: Bool) -> Observable<Result<Int>>
//
//    /**API_S004: Get sharing book to display on app home page*/
//    func getHomePublicSharingBookEdition(page: Int, perPage: Int, isLoading: Bool) -> Observable<Result<[BookEdition]>>
//
//    //MARK: - 6. Suggestion API(s)
//    //MARK: - 7. Common API(s)
//    /**API_C001: Get image from flickr*/
//    func getImage(imageId: String, imageSize: GaTImageSize) -> String
//
//    /**API_C002: Check app version*/
//    func checkAppVersion(currentVersion: String, isLoading: Bool) -> Observable<Result<Bool>>
//}
//
///**Quản lý các kết nối API lên GaT Server*/
//class GaTDefaultAPI: GaTAPI {
////    let log = XCGLogger.default
//
//    let baseURL: String = AppConfig.sharedConfig.get("api_url")
//
//    /**Cài đặt mẫu SingleTon*/
//    static let shared = GaTDefaultAPI()
//
//    //MARK: - Implement: 1. User Authentication API(s)
//    /**API_U001.1: Đăng ký tài khoản bằng email*/
//    func register(email: String, name: String, password: String, isLoading: Bool = true) -> Observable<Result<Session>> {
//        let actionURL = self.baseURL + "user/register_by_email"
//        let parameters: Parameters = [
//            "email": email,
//            "name": name,
//            "password": password,
//            "uuid": AppConfig.sharedConfig.uuid()
//        ]
//        let method = HTTPMethod.post
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleAuthResult($0, authType: .None, secret: password)
//        }
//    }
//
//    /**API_U001.2: Đăng ký tài khoảng bằng social*/
//    func socialNetworkRegister(socialID: String, socialType: SocialNetworkType, name: String, email: String, password: String, avatarData: UIImage, authId: String = "", secretToken: String = "", isLoading: Bool = true) -> Observable<Result<Session>> {
//        let actionURL = self.baseURL + "user/register_by_social"
//        let parameters: Parameters = [
//            "Image": avatarData.toBase64(),
//            "socialID": socialID,
//            "socialType": String(socialType.rawValue),
//            "name": name,
//            "email": email,
//            "password": password,
//            "uuid": AppConfig.sharedConfig.uuid()
//        ]
//        let method = HTTPMethod.post
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleAuthResult($0, authType: socialType, secret: socialID, authId: authId, secretToken: secretToken)
//        }
//    }
//
//    /**API_U002.1: Đăng nhập tài khoản bằng email*/
//    func attempt(email: String, password: String, isLoading: Bool = true) -> Observable<Result<Session>> {
//        let actionURL = self.baseURL + "user/login_by_email"
//        let parameters: Parameters = [
//            "email": email,
//            "password": password,
//            "uuid": AppConfig.sharedConfig.uuid()
//        ]
//        let method = HTTPMethod.post
//
//        /*Có LoginToken*/
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleAuthResult($0, authType: .None, secret: password)
//        }
//    }
//
//    /**API_U002.2: Đăng nhập tài khoảng bằng social*/
//    func oAuthAttempt(token: String, socialNetworkType: SocialNetworkType, authId: String = "", secretToken: String = "", isLoading: Bool = true) -> Observable<Result<Session>> {
//        let actionURL = self.baseURL + "user/login_by_social"
//        let parameters: Parameters = [
//            "socialID": token,
//            "socialType": socialNetworkType.rawValue,
//            "uuid": AppConfig.sharedConfig.uuid()
//        ]
//        let method = HTTPMethod.post
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleAuthResult($0, authType: socialNetworkType, secret: token, authId: authId, secretToken: secretToken)
//        }
//    }
//
//    /**API_U002.3: Sign out*/
//    func logout(isLoading: Bool = true) -> Observable<Result<String>> {
//        let actionURL = self.baseURL + "user/sign_out"
//
//        let parameters: Parameters = [
//            "uuid": AppConfig.sharedConfig.uuid()
//        ]
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGenerallyInformResult($0)
//        }
//    }
//
//    /**API_U003: Send yêu cầu reset pass by email (gửi token 6 chữ số về email)*/
//    func requestResetPasswordToken(email: String, isLoading: Bool = true) -> Observable<Result<ResetPasswordResult>> {
//        let actionURL = self.baseURL + "user/request_reset_password"
//        let parameters: Parameters = [
//            "email": email
//        ]
//        let method = HTTPMethod.post
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleRequestResetPasswordToken($0)
//        }
//    }
//
//    /**API_U004: Verify reset token*/
//    func verifyResetCode(tokenResetPassword: String, code: String, isLoading: Bool = true) -> Observable<Result<String>> {
//        let actionURL = self.baseURL + "user/verify_reset_token"
//        let parameters: Parameters = [
//            "code": code,
//            "tokenResetPassword": tokenResetPassword
//        ]
//
//        let method = HTTPMethod.post
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleVerifyResetCode($0)
//        }
//    }
//
//    /**API_U005: Reset password*/
//    func changePassword(tokenVerify: String, password: String, isLoading: Bool = true) -> Observable<Result<Session>> {
//        let actionURL = self.baseURL + "user/reset_password"
//        let parameters: Parameters = [
//            "newPassword": password,
//            "tokenVerify": tokenVerify,
//            "uuid": AppConfig.sharedConfig.uuid()
//        ]
//        let method = HTTPMethod.post
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleAuthResult($0, authType: .None, secret: password)
//        }
//    }
//
//    //MARK: - Implement: 2. User Info API(s)
//    /**API_U006: Update user information*/
//    func updateUserInfo(name: String, Image: UIImage, changeImageFlag: Bool = true, isLoading: Bool = true) -> Observable<Result<String>> {
//        let actionURL = self.baseURL + "user/update_user_info_ios"
//
//        var imageData: String = ""
//
//        if changeImageFlag == true {
//            imageData = Image.toBase64()
//        }
//        var parameters: Parameters = [
//            "name": name,
//            "image": imageData,
//            "changeImageFlag": changeImageFlag
//        ]
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                parameters["loginToken"] = session.token
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleUpdateUserInformationResult($0)
//        }
//    }
//
//    /**API_U007: Update favourite book category*/
//    func saveFavoriteCategory(categoryList: [Int], isLoading: Bool = true) -> Observable<Result<String>> {
//        guard categoryList.count > 0 else {
//            return Observable.just(Result<String>.Success("Đã bỏ qua"))
//        }
//
//        let actionURL = self.baseURL + "user/update_favorite_category"
//        var categoryListString = ""
//
//        for i in 0..<categoryList.count
//        {
//            if (i < categoryList.count - 1) {
//                categoryListString += String(categoryList[i]) + ", "
//            } else {
//                categoryListString += String(categoryList[i])
//            }
//        }
//
//        let parameters: Parameters = [
//            "categories": categoryListString
//        ]
//
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGenerallyInformResult($0)
//        }
//    }
//
//    /**API_U008: Update usually location*/
//    func updateUsuallyLocation(address: String, latitude: Double, longitude: Double, isLoading: Bool = true) -> Observable<Result<String>> {
//        let actionURL = self.baseURL + "user/update_usually_location"
//        let parameters: Parameters = [
//            "address": address,
//            "latitude": latitude,
//            "longitude": longitude
//        ]
//
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGenerallyInformResult($0)
//            }
//    }
//
//    /**API_U009: Get user detail information*/
//    func getLoginUserInfo(isLoading: Bool = true) -> Observable<Result<User>> {
//        let actionURL = self.baseURL + "user/get_user_private_info"
//        let parameters: Parameters = [:]
//        let method = HTTPMethod.get
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                /*Phân tích JSON trả về từ Network và tạo ra một Stream User*/
//                return self.handleLoginUserInfo($0)
//        }
//    }
//
//    /**API_U010: Get public info of other user*/
//    func getUserPublicInfo(userId: Int, isLoading: Bool = true) -> Observable<Result<User>> {
//        let actionURL = self.baseURL + "user/get_user_public_info"
//
//        let parameters: Parameters = [
//            "userId": userId
//        ]
//        let method = HTTPMethod.get
//
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleLoginUserInfo($0)
//        }
//    }
//
//    /**API_U011: User liên kết social*/
//    func linkSocial(socialID: String, socialName: String, socialType: SocialNetworkType, isLoading: Bool = true) -> Observable<Result<String>> {
//        let actionURL = self.baseURL + "user/link_social_acc"
//
//        let parameters: Parameters = [
//            "socialID": socialID,
//            "socialName": socialName,
//            "socialType": socialType.rawValue
//        ]
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGenerallyInformResult($0)
//        }
//    }
//
//    /**API_U012: User huỷ liên kết social*/
//    func unlinkSocial(socialType: SocialNetworkType, isLoading: Bool = true) -> Observable<Result<String>> {
//        let actionURL = self.baseURL + "user/unlink_social_acc"
//
//        let parameters: Parameters = [
//            "socialType": socialType.rawValue
//        ]
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGenerallyInformResult($0)
//        }
//    }
//
//    /**API_U014: User thêm email và password*/
//    func addEmailPassword(email: String, password: String, isLoading: Bool = true) -> Observable<Result<Session>> {
//        let actionURL = self.baseURL + "user/add_email_pass"
//
//        let parameters: Parameters = [
//            "email": email,
//            "password": password
//        ]
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleAuthResult($0, authType: .None, secret: password)
//        }
//    }
//
//    /**API_U015: User thay đổi mật khẩu*/
//    func updatePassword(oldPassword: String, newPassword: String, isLoading: Bool = true) -> Observable<Result<Session>> {
//        let actionURL = self.baseURL + "user/change_password"
//
//        let parameters: Parameters = [
//            "oldPassword": oldPassword,
//            "newPassword": newPassword,
//            "uuid": AppConfig.sharedConfig.uuid()
//        ]
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleAuthResult($0, authType: .None, secret: newPassword)
//        }
//    }
//
//    /**API_U016: Firebase token register
//
//     - Đăng ký FirebaseToken lấy từ:
//     https://firebase.google.com/docs/reference/ios/firebaseinstanceid/api/reference/Classes/FIRInstanceID*/
//    func registerFirebaseToken(token: String, isLoading: Bool = true) ->  Observable<Result<String>> {
//        let actionURL = self.baseURL + "user/firebase_token_register"
//
//        let parameters: Parameters = [
//            "firebaseToken": token,
//            "uuid": AppConfig.sharedConfig.uuid()
//        ]
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGenerallyInformResult($0)
//        }
//    }
//
//    //MARK: - Implement: 3. Reading & Book API(s)
//    /**API_R001: Lấy thông tin chi tiết về sách, bao gồm thông tin sách, tác giả, category, rate avg, sharing count…*/
//    func getBookEditionDetailBy(id: Int, isLoading: Bool = true) -> Observable<Result<BookEdition>> {
//        let actionURL = self.baseURL + "book/get_book_info"
//
//        let parameters: Parameters = [
//            "editionId": id
//        ]
//        let method = HTTPMethod.get
//
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleBookEditionDetail($0)
//        }
//    }
//
//    /**API_R003: Lấy list các book instance của mình (kèm tên người mượn nếu có)*/
//    func getUserBookInstant(filterData: [String: String], page: Int = 1, perPage: Int = 10, isLoading: Bool = true) -> Observable<Result<BorrowingBookInstantResult>>{
//        let actionURL = self.baseURL + "book/selfget_book_instance"
//
//        let parameters: Parameters = [
//            "sharingFilter": filterData["sharingFilter"]!,
//            "notSharingFilter": filterData["notSharingFilter"]!,
//            "lostFilter": filterData["lostFilter"]!,
//            "page": page,
//            "per_page": perPage
//        ]
//
//        let method = HTTPMethod.get
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleUserBookInstantResult($0)
//        }
//    }
//
//    /**API_R004: Lấy list các book đang public sharing của user khác*/
//    func getPublicSharingBookEdition(ownerId: Int, userId: Int = -1, page: Int = 1, perPage: Int = 10, isLoading: Bool = true) -> Observable<Result<(Int, List<PublicSharingBookEdition>)>> {
//        let actionURL = self.baseURL + "book/get_user_sharing_editions"
//        let parameters: Parameters = [
//            "ownerId": ownerId,
//            "userId": userId,
//            "page": page,
//            "per_page": perPage
//        ]
//        let method = HTTPMethod.get
//
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handlePublicSharingBookEditionInfo($0)
//        }
//    }
//
//    /**API_R005: Remove book instance*/
//    func deleteUserBookInstant(instantId: Int = -1, isLoading: Bool = true) -> Observable<Result<String>> {
//        let actionURL = self.baseURL + "book/selfremove_instance"
//
//        let parameters: Parameters = [
//            "instanceId": instantId
//        ]
//
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGenerallyInformResult($0)
//        }
//    }
//
//
//    /**API_R006: Change book instance sharing status*/
//    func updateUserBookInstantStatus(instantId: Int = -1, sharingStatus: Int = -1, isLoading: Bool = true) -> Observable<Result<String>> {
//        let actionURL = self.baseURL + "book/selfchange_instance_stt"
//
//        let parameters: Parameters = [
//            "instanceId": instantId,
//            "sharingStatus": sharingStatus
//        ]
//
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGenerallyInformResult($0)
//        }
//    }
//
//    /**API_R008: Lấy thông tin đọc (reading info - bao gồm read, reading, to read) của user (kèm thông tin mượn từ ai - nếu có)*/
//    func getUserReadingBookInstant(userId: Int, filterData: [String: String], page: Int = 1, perPage: Int = 10, isLoading: Bool = true) -> Observable<Result<ReadingBookInstantResult>>{
//        let actionURL = self.baseURL + "book/get_user_reading_editions"
//        let parameters: Parameters = [
//            "readingFilter": filterData["readingFilter"]!,
//            "toReadFilter": filterData["toReadFilter"]!,
//            "readFilter": filterData["readFilter"]!,
//            "userId": userId,
//            "page": page,
//            "per_page": perPage
//            ]
//        let method = HTTPMethod.get
//
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleUserReadingBookInstantResult($0)
//        }
//    }
//
//    //MARK: - Implement: 4. Sharing & Borrowing API(s)
//    /**API_B001: Get book borrowing record/request*/
//    func getBorrowingBookRequest(filterData: [String: String], page: Int = 1, perPage: Int = 10, isLoading: Bool = true) -> Observable<Result<BorrowingBookRequestResult>> {
//        let actionURL = self.baseURL + "share/get_book_record"
//        let parameters: Parameters = [
//            "sharingFilter": filterData["sharingFilter"]!,
//            "borrowingFilter": filterData["borrowingFilter"]!,
//            "page": page,
//            "per_page": perPage
//            ]
//        let method = HTTPMethod.get
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleBorrowingBookRequestResult($0)
//            }
//    }
//
//    /**API_B002: Create borrowing request*/
//    func createBorrowingRequest(ownerId: Int, editionId: Int, isLoading: Bool = true) -> Observable<Result<BorrowingBookRequest>> {
//        let actionURL = self.baseURL + "share/create_request"
//
//        let parameters: Parameters = [
//            "ownerId": ownerId,
//            "editionId": editionId
//        ]
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGetBorrowingRequestDetailResult($0, isDetail: false)
//        }
//    }
//
//    /**API_B003A: Update status of borrowing request by owner*/
//    func updateRequestByOwner(recordId: Int, currentStatus: Int, newStatus: Int, isLoading: Bool = true) -> Observable<Result<(Int, Int)>> {
//        let actionURL = self.baseURL + "share/update_request_by_owner"
//
//        let parameters: Parameters = [
//            "recordId": recordId,
//            "currentStatus": currentStatus,
//            "newStatus": newStatus
//        ]
//
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleRequestDetailResult($0, currentStatus: currentStatus, newStatus: newStatus)
//        }
//    }
//
//    /**API_B003B: Update status of borrowing request by borrower*/
//    func updateRequestByBorrower(recordId: Int, currentStatus: Int, newStatus: Int, isLoading: Bool = true) -> Observable<Result<(Int, Int)>> {
//        let actionURL = self.baseURL + "share/update_request_by_borrower"
//
//        let parameters: Parameters = [
//            "recordId": recordId,
//            "currentStatus": currentStatus,
//            "newStatus": newStatus
//        ]
//
//        let method = HTTPMethod.post
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleRequestDetailResult($0, currentStatus: currentStatus, newStatus: newStatus)
//        }
//    }
//
//    /**API_B004: Get detail information of request*/
//    func getBorrowingRequestDetail(recordId: Int, isLoading: Bool = true) -> Observable<Result<BorrowingBookRequest>> {
//        let actionURL = self.baseURL + "share/get_request_info"
//
//        let parameters: Parameters = [
//            "recordId": recordId
//        ]
//        let method = HTTPMethod.get
//
//        return Auth.shared.getActiveSession().flatMapLatest { (result) -> Observable<Result<JSON>> in
//            switch result {
//            case .Success(let session):
//                return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, session: session, isLoading: isLoading)
//            case .Failure(let message):
//                return Observable<Result<JSON>>.just(Result<JSON>.Failure(message))
//            }
//            }.flatMapLatest {
//                self.handleGetBorrowingRequestDetailResult($0)
//        }
//    }
//
//    //MARK: - Implement: 5. Searching API(s)
//    /**API_S002: Search book by isbn Result is one book*/
//    func getBookEditionIdBy(isbn: String, isLoading: Bool = true) -> Observable<Result<Int>> {
//        let actionURL = self.baseURL + "search/book_by_isbn"
//
//        let parameters: Parameters = [
//            "isbn": isbn
//        ]
//        let method = HTTPMethod.get
//
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleBookEditionFromISBN($0)
//        }
//    }
//
//    /**API_S004: Get sharing book to display on app home page*/
//    func getHomePublicSharingBookEdition(page: Int, perPage: Int = 10, isLoading: Bool = true) -> Observable<Result<[BookEdition]>> {
//        let actionURL = self.baseURL + "suggestion/book_suggestion"
//
//        let parameters: Parameters = [
//            "page": page,
//            "per_page": perPage
//        ]
//        let method = HTTPMethod.get
//
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handlePublicSharingBookEditionResult($0)
//        }
//    }
//
//    //MARK: - Implement: 6. Suggestion API(s)
//    //MARK: - Implement: 7. Common API(s)
//    /**API_C001: Get image from flickr*/
//    func getImage(imageId: String, imageSize: GaTImageSize = .s) -> String {
//        let actionURL = self.baseURL + "common/get_image/\(imageId)?size=\(imageSize.rawValue)"
//        return actionURL
//    }
//
//    /**API_C002: Check app version*/
//    func checkAppVersion(currentVersion: String, isLoading: Bool = true) -> Observable<Result<Bool>> {
//        let actionURL = self.baseURL + "common/check_version"
//        let parameters: Parameters = [
//            "deviceType": 1,
//            "version": currentVersion
//        ]
//        let method = HTTPMethod.get
//
//        return self.sendRequest(actionURL: actionURL, method: method, parameters: parameters, isLoading: isLoading).flatMapLatest {
//            self.handleCheckAppVersionResult($0)
//        }
//    }
//
//    //MARK: - HELPER METHODS
//    private let disposeBag = DisposeBag()
//
//    /**Tạo dòng gửi request lên server*/
//    private func sendRequest(actionURL: String, method: HTTPMethod = HTTPMethod.post, parameters: Parameters, session: Session? = nil, isLoading: Bool) -> Observable<Result<JSON>> {
//        return Observable<Result<JSON>>.create({ (observer) -> Disposable in
//            var headers = [String: String]()
//
//            /**Cài đặt loading icon*/
//            weak var topViewController = UIApplication.topViewController()
//            let fullScreenLoadingView = UIStoryboard(name: "GlobalLoading", bundle: nil).instantiateViewController(withIdentifier: "GlobalLoadingView") as? GlobalLoadingViewController
//
//            if isLoading, let frame = topViewController?.view.frame {
//                fullScreenLoadingView?.view.frame = frame
//                topViewController?.view.addSubview((fullScreenLoadingView?.view)!)
//            }
//
//            // Đặt ngôn ngữ yêu cầu mặc định, nếu người dùng có cài đặt ngôn ngữ cụ thể
//            headers["Accept-Language"] = NSLocalizedString("Accept-Language", comment: "")
//
//            if let tmpSession = session {
//                /*Lấy ra lginToken để nhét vào header*/
//                headers["Authorization"] = tmpSession.token
//            }
//
////            self.log.debug(actionURL)
////            self.log.debug(headers)
////            self.log.debug(parameters)
//
//            let request = Alamofire.request(actionURL, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers)
////            print("####: BEGIN: ", actionURL)
//            request.responseJSON { response in
//                /**Tắt loading*/
//                fullScreenLoadingView?.view.removeFromSuperview()
////                print("####: FINISHED: ", response.result)
//                if let err = response.error as? URLError, err.code  == URLError.Code.notConnectedToInternet {
//                    observer.onNext(Result<JSON>.Failure(.Offline("503")))
//                } else if let statusCode = response.response?.statusCode {
//                    switch statusCode {
//                    case 200:
//                        observer.onNext(Result<JSON>.Success(JSON(response.result.value!)))
//                    case 400:
//                        let json = JSON(response.result.value!)
//                        observer.onNext(Result<JSON>.Failure(.General(json["message"].string!)))
//                    case 401:
//                        let json = JSON(response.result.value!)
//                        observer.onNext(Result<JSON>.Failure(.Unauthorized(json["message"].string!)))
//                    case 409:
//                        let json = JSON(response.result.value!)
//                        observer.onNext(Result<JSON>.Failure(.OldData(json["message"].string!)))
//                    default:
//                        observer.onNext(Result<JSON>.Failure(.Offline("503")))
//                    }
//                    // Gui len Firebase tất cả các lỗi
//                    if statusCode != 200 {
//                        var resultMessage: String = "";
//                        if let errorResult = response.result.value {
//                            resultMessage = JSON(errorResult)["message"].string ?? ""
//                        }
//                        FIRAnalytics.logEvent(withName: "gat_api_error", parameters: [
//                            "gat_url": actionURL as NSObject,
//                            "gat_params": parameters.json as NSObject,
//                            "gat_code": statusCode,
//                            "gat_result": resultMessage as NSObject
//                        ])
//                    }
//                }
//            }
//            return Disposables.create()
//        })
//    }
//
//    /*Tạo dòng gửi upload request lên server*/
//    private func sendUploadDataRequest(actionURL: String, method: HTTPMethod = HTTPMethod.post, uploadName: String, dataUpload: Data, parameters: Parameters, session: Session? = nil) -> Observable<Result<JSON>> {
//        return Observable<Result<JSON>>.create({ (observer) -> Disposable in
//            var headers = [String: String]()
//
//            // Đặt ngôn ngữ yêu cầu mặc định, nếu người dùng có cài đặt ngôn ngữ cụ thể
//            headers["Accept-Language"] = "vi"
//
//            if let tmpSession = session {
//                /*Lấy ra lginToken để nhét vào header
//                 Mặc định tất cả các request đều phải có Accept-Language*/
//                headers["Accept-Language"] = tmpSession.acceptLanguage
//                headers["Authorization"] = tmpSession.token
//            }
//
////            self.log.debug(headers)
////            self.log.debug(parameters)
////            self.log.debug(dataUpload)
//
//            Alamofire.upload(multipartFormData:{ (multipartFormData) in
//                multipartFormData.append(dataUpload, withName: uploadName, fileName: "avatar.jpg", mimeType: "image/jpg")
//                for (key, value) in parameters {
//                    multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
//                }
//            }, to: actionURL, method: method, headers: headers, encodingCompletion: { encodingResult in
//                switch encodingResult {
//                case .success(let upload, _, _):
//                    upload.uploadProgress { progress in
////                        self.log.debug(progress)
//                    }
//                    upload.validate()
//                    upload.responseString(completionHandler: { (data) in
//                        print("Alamofire: ***", data)
//                    })
//                    upload.responseJSON { response in
////                        self.log.debug(response)
//                        if let statusCode = response.response?.statusCode {
//                            switch statusCode {
//                            case 200:
//                                if let result = response.result.value {
//                                    observer.onNext(Result<JSON>.Success(JSON(result)))
//                                } else{
////                                    self.log.debug("Invalid JSON")
//                                    observer.onNext(Result<JSON>.Failure(.General("Invalid JSON")))
//                                }
//                            case 400:
//                                if let result = response.result.value {
//                                    let json = JSON(result)
//                                    observer.onNext(Result<JSON>.Failure(.General(json["message"].string!)))
//                                } else{
////                                    self.log.debug("Account exists or invalid JSON")
//                                    observer.onNext(Result<JSON>.Failure(.General("Account exists or invalid data")))
//                                }
//                            default:
////                                self.log.debug("Unknown error")
//                                observer.onNext(Result<JSON>.Failure(.General("Unknown error")))
//                                break
//                            }
//                        } else {
////                            self.log.debug("Unknown error")
//                            observer.onNext(Result<JSON>.Failure(.General("Unknown error")))
//                        }
//                    }
//                case .failure(let encodingError): break
////                    self.log.debug(encodingError)
//                }
//            })
//            return Disposables.create()
//        })
//    }
//
//    /**Tạo dòng xử lý kết quả trả về cho các tính năng liên quan tới Auth như Login và Register */
//    private func handleAuthResult(_ result: Result<JSON>, authType: SocialNetworkType, secret: String, authId: String = "", secretToken: String = "") -> Observable<Result<Session>> {
//        switch result {
//            case .Success(let json):
//                print("json", json)
//            return Observable<Result<(String, String)>>.create { observer in
//
//                if json["data"].exists() {
//                    let firebasePassword = json["data"]["firebasePassword"].string ?? ""
//                    let loginToken = json["data"]["loginToken"].string ?? ""
//                    let authInformation = (loginToken, firebasePassword)
//                    observer.onNext(Result<(String, String)>.Success(authInformation))
//                } else if let message = json["message"].string {
//                    observer.onNext(Result<(String, String)>.Failure(.General(message)))
//                }
//                return Disposables.create()
//                }.flatMapLatest { (result) -> Observable<Result<Session>> in
//                    switch result {
//                    case .Success(let (loginToken, firebasePassword)):
//                        //Tạo session với token tại đây
//                        let session = Session()
//                        session.id = session.nextId()
//                        session.token = loginToken
//                        session.isActive = true
//                        session.authType = authType.rawValue
//                        session.firebasePassword = firebasePassword
//                        if authType == .None {
//                            session.password = secret
//                        } else {
//                            session.socialSecretKey = secret
//                        }
//                        session.authId = authId
//                        session.secretToken = secretToken
//                        return Observable.just(Result<Session>.Success(session))
//                    case .Failure(let loginErrorMessage):
//                        return Observable.just(Result<Session>.Failure(loginErrorMessage))
//                    }
//            }
//            case .Failure(let message): return Observable.just(Result<Session>.Failure(message))
//        }
//    }
//
//    /**Tạo dòng xử lý kết quả lấy thông tin ngời dùng đang đăng nhập*/
//    private func handleLoginUserInfo(_ result: Result<JSON>) -> Observable<Result<User>> {
//        switch result {
//        case .Success(let json):
//            if let user = User.parseFrom(json: json["data"]["resultInfo"]) {
//                return Observable.just(Result<User>.Success(user))
//            } else {
//                return Observable.just(Result<User>.Failure(.General("Kiểm tra lại cấu trúc API User")))
//            }
//        case .Failure(let message): return Observable.just(Result<User>.Failure(message))
//        }
//    }
//
//    /**Xử lý kết quả trả về của API đổi trạng thái BorrowingRequest*/
//    private func handleRequestDetailResult(_ result: Result<JSON>, currentStatus: Int, newStatus: Int) -> Observable<Result<(Int, Int)>> {
//        switch result {
//        case .Success(let json):
//            return Observable<Result<(Int, Int)>>.create { observer in
//                if let _ = json["message"].string {
//                    let result = (currentStatus, newStatus)
//                    observer.onNext(Result<(Int, Int)>.Success(result))
//                }
//                return Disposables.create()
//            }
//        case .Failure(let message): return Observable<Result<(Int, Int)>>.just(Result<(Int, Int)>.Failure(message))
//        }
//    }
//
//    private func handleUpdateUserInformationResult(_ result: Result<JSON>) -> Observable<Result<String>> {
//        switch result {
//        case .Success(let json):
//            return Observable<Result<String>>.create { observer in
//                let imageId = json["data"]["imageId"].string ?? ""
//                observer.onNext(Result<String>.Success(imageId))
//                return Disposables.create()
//            }
//        case .Failure(let message): return Observable<Result<String>>.just(Result<String>.Failure(message))
//        }
//    }
//
//    /**Tạo dòng xử lý kết quả trả về chung cho các JSON dạng
//     {
//     "message": message content,
//     }*/
//    private func handleGenerallyInformResult(_ result: Result<JSON>) -> Observable<Result<String>> {
//        switch result {
//        case .Success(let json):
//            return Observable<Result<String>>.create { observer in
//                if let message = json["message"].string {
//                    observer.onNext(Result<String>.Success(message))
//                }
//                return Disposables.create()
//            }
//        case .Failure(let message): return Observable<Result<String>>.just(Result<String>.Failure(message))
//        }
//    }
//
//    /**Tạo dòng xử lý kết quả lấy mã yêu cầu khôi phục mật khẩu*/
//    private func handleRequestResetPasswordToken(_ result: Result<JSON>) -> Observable<Result<ResetPasswordResult>> {
//        switch result {
//        case .Success(let json):
//            return Observable<Result<ResetPasswordResult>>.create { observer in
//                let tokenResetPassword = json["data"]["tokenResetPassword"].string ?? ""
//                var socialType: SocialNetworkType?
//                if let tmpSocialType = json["data"]["socialType"].int {
//                    switch tmpSocialType {
//                    case 0:
//                        socialType = SocialNetworkType.None
//                    case 1:
//                        socialType = SocialNetworkType.Facebook
//                    case 2:
//                        socialType = SocialNetworkType.Google
//                    case 3:
//                        socialType = SocialNetworkType.Twitter
//                    default:
//                        break
//                    }
//                }
//                let socialId = json["data"]["socialId"].string ?? ""
//                let socialName = json["data"]["socialName"].string ?? ""
//
//                if let tmpSocialType = socialType {
//                    let requestResetPasswordResult: ResetPasswordResult = (tokenResetPassword, tmpSocialType, socialId, socialName)
//                    observer.onNext(Result<ResetPasswordResult>.Success(requestResetPasswordResult))
//                } else {
//                    observer.onNext(Result<ResetPasswordResult>.Failure(HTError.Silent("Lỗi API")))
//                }
//
//                return Disposables.create()
//            }
//        case .Failure(let message): return Observable<Result<ResetPasswordResult>>.just(Result<ResetPasswordResult>.Failure(message))
//        }
//    }
//
//    /**Tạo dòng xử lý kết quả lấy mã yêu cầu khôi phục mật khẩu*/
//    private func handleVerifyResetCode(_ result: Result<JSON>) -> Observable<Result<String>> {
//        switch result {
//        case .Success(let json):
//            return Observable<Result<String>>.create { observer in
//                if let code = json["data"]["tokenVerify"].string {
//                    observer.onNext(Result<String>.Success(code))
//                }
//                return Disposables.create()
//            }
//        case .Failure(let message): return Observable<Result<String>>.just(Result<String>.Failure(message))
//        }
//    }
//
//    /**Xử lý kết quả BookInstant của từng người dùng*/
//    private func handleUserBookInstantResult(_ result: Result<JSON>) -> Observable<Result<BorrowingBookInstantResult>> {
//        switch result {
//        case .Success(let json):
//            return Observable<Result<BorrowingBookInstantResult>>.create { observer in
//                let sharingTotal: Int = json["data"]["sharingTotal"].int ?? 0
//                let notSharingTotal: Int = json["data"]["notSharingTotal"].int ?? 0
//                let lostTotal: Int = json["data"]["lostTotal"].int ?? 0
//
//                let bookListResult = List<BookInstant>()
//                if let bookListJSON = json["data"]["resultInfo"].array {
//                    for item in bookListJSON {
//                        if let bookInstant = BookInstant.parseFrom(json: item) {
//                            bookListResult.append(bookInstant)
//                        }
//                    }
//                }
//                let result: BorrowingBookInstantResult = (sharingTotal, notSharingTotal, lostTotal, bookListResult)
//                /*Truy vấn lại danh sách từ DB*/
//                observer.onNext(Result<BorrowingBookInstantResult>.Success(result))
//                return Disposables.create()
//            }
//        case .Failure(let message): return Observable<Result<BorrowingBookInstantResult>>.just(Result<BorrowingBookInstantResult>.Failure(message))
//        }
//    }
//
//    /**Xử lý kết quả sách đang đọc của từng người dùng*/
//    private func handleUserReadingBookInstantResult(_ result: Result<JSON>) -> Observable<Result<ReadingBookInstantResult>> {
//        switch result {
//        case .Success(let json):
//            return Observable<Result<ReadingBookInstantResult>>.create { observer in
//                let readingTotal: Int = json["data"]["readingTotal"].int ?? 0
//                let toReadTotal: Int = json["data"]["toReadTotal"].int ?? 0
//                let readTotal: Int = json["data"]["readTotal"].int ?? 0
//
//                let bookListResult = List<ReadingBookInstant>()
//                if let bookListJSON = json["data"]["resultInfo"].array {
//                    for item in bookListJSON {
//                        if let readingBook = ReadingBookInstant.parseFrom(json: item) {
//                            bookListResult.append(readingBook)
//                        }
//                    }
//                }
//
//                /*Truy vấn lại danh sách từ DB*/
//                let result: ReadingBookInstantResult = (readingTotal, toReadTotal, readTotal, bookListResult)
//                observer.onNext(Result<ReadingBookInstantResult>.Success(result))
//                return Disposables.create()
//            }
//        case .Failure(let message): return Observable<Result<ReadingBookInstantResult>>.just(Result<ReadingBookInstantResult>.Failure(message))
//        }
//    }
//
//    /*Xử lý request của người dùng hiện tại đang login*/
//    private func handleBorrowingBookRequestResult(_ result: Result<JSON>) -> Observable<Result<BorrowingBookRequestResult>> {
//        switch result {
//        case .Success(let json):
//            return Observable<Result<BorrowingBookRequestResult>>.create { observer in
//                let waitingTotal: Int = json["data"]["waitingTotal"].int ?? 0
//                let sharingTotal: Int = json["data"]["sharingTotal"].int ?? 0
//                let borrowingTotal: Int = json["data"]["borrowingTotal"].int ?? 0
//
//                let requestResults = List<BorrowingBookRequest>()
//                if let requestListJSON = json["data"]["resultInfo"].array {
//                    for item in requestListJSON {
//                        if let borrowingRequest = BorrowingBookRequest.parseFrom(json: item) {
//                            requestResults.append(borrowingRequest)
//                        }
//                    }
//                }
//                let result: BorrowingBookRequestResult = (waitingTotal, sharingTotal, borrowingTotal, requestResults)
//                /*Truy vấn lại danh sách từ DB*/
//                observer.onNext(Result<BorrowingBookRequestResult>.Success(result))
//                return Disposables.create()
//            }
//        case .Failure(let message): return Observable<Result<BorrowingBookRequestResult>>.just(Result<BorrowingBookRequestResult>.Failure(message))
//        }
//    }
//
//    /**Xử lý BookEdition trả về*/
//    func handleBookEditionFromISBN(_ result: Result<JSON>) -> Observable<Result<Int>> {
//        switch result {
//        case .Success(let jsonResult):
//            return Observable<Result<Int>>.just(Result<Int>.Success(jsonResult["data"]["editionId"].int!))
//        case .Failure(let message):
//            return Observable<Result<Int>>.just(Result<Int>.Failure(message))
//        }
//    }
//
//    /**Xử lý list bookEdition*/
//    func handlePublicSharingBookEditionResult(_ result: Result<JSON>) -> Observable<Result<[BookEdition]>>{
//        switch result {
//        case .Success(let jsonResult):
//            if let bookEditions = jsonResult["data"]["resultInfo"].array {
//                var bookEditionList: [BookEdition] = []
//                for bookEditionJson in bookEditions {
//                    if let bookEdition = BookEdition.parseFrom(json: bookEditionJson) {
//                        bookEditionList.append(bookEdition)
//                    }
//                }
//                return Observable<Result<[BookEdition]>>.just(Result<[BookEdition]>.Success(bookEditionList))
//            } else {
//                return Observable<Result<[BookEdition]>>.just(Result<[BookEdition]>.Failure(.General("Dữ liệu trả về không hợp lệ")))
//            }
//        case .Failure(let message):
//            return Observable<Result<[BookEdition]>>.just(Result<[BookEdition]>.Failure(message))
//        }
//    }
//
//    /**Xử lý BookEditionDetail trả về*/
//    func handleBookEditionDetail(_ result: Result<JSON>) -> Observable<Result<BookEdition>> {
//        switch result {
//        case .Success(let jsonResult):
//            if let bookEdition = BookEdition.parseFrom(json: jsonResult["data"]["resultInfo"]) {
//                return Observable<Result<BookEdition>>.just(Result<BookEdition>.Success(bookEdition))
//            } else {
//                return Observable<Result<BookEdition>>.just(Result<BookEdition>.Failure(.General("Dữ liệu trả về không hợp lệ")))
//            }
//        case .Failure(let message):
//            return Observable<Result<BookEdition>>.just(Result<BookEdition>.Failure(message))
//        }
//    }
//
//    /**Xử lý JSON lấy kết quả sharingEdition của public user visitor*/
//    func handlePublicSharingBookEditionInfo(_ result: Result<JSON>) -> Observable<Result<(Int, List<PublicSharingBookEdition>)>> {
//         switch result {
//         case .Success(let jsonResult):
//            let totalSharing = jsonResult["data"]["sharingTotal"].int ?? 0
//            let bookEditions = List<PublicSharingBookEdition>()
//
//            if let requestListJSON = jsonResult["data"]["resultInfo"].array {
//                for item in requestListJSON {
//                    if let bookEdition = PublicSharingBookEdition.parseFrom(json: item) {
//                        bookEditions.append(bookEdition)
//                    }
//                }
//            }
//            let result = (totalSharing, bookEditions)
//            return Observable<Result<(Int, List<PublicSharingBookEdition>)>>.just(Result<(Int, List<PublicSharingBookEdition>)>.Success(result))
//         case .Failure(let error):
//            return Observable<Result<(Int, List<PublicSharingBookEdition>)>>.just(Result<(Int, List<PublicSharingBookEdition>)>.Failure(error))
//         }
//    }
//
//    private func handleGetBorrowingRequestDetailResult(_ result: Result<JSON>, isDetail: Bool = true) -> Observable<Result<BorrowingBookRequest>> {
//        switch result {
//        case .Success(let json):
//            print(json)
//            if let borrowingRequest = BorrowingBookRequest.parseFrom(json: json["data"]["resultInfo"], isDetail: isDetail) {
//                return Observable<Result<BorrowingBookRequest>>.just(Result<BorrowingBookRequest>.Success(borrowingRequest))
//            } else {
//                return Observable<Result<BorrowingBookRequest>>
//                    .just(Result<BorrowingBookRequest>.Failure(.General("Kiểm tra API trả về Borrowing Request Detail")))
//            }
//        case .Failure(let error):
//            return Observable<Result<BorrowingBookRequest>>.just(Result<BorrowingBookRequest>.Failure(error))
//        }
//    }
//
//    private func handleCheckAppVersionResult(_ result: Result<JSON>) -> Observable<Result<Bool>> {
//        switch result {
//        case .Success(let json):
//            if let needToUpdate = json["data"]["needToUpdate"].bool {
//                return Observable<Result<Bool>>.just(Result<Bool>.Success(needToUpdate))
//            } else {
//                return Observable<Result<Bool>>
//                    .just(Result<Bool>.Failure(.General("Kiểm tra API trả về Borrowing Request Detail")))
//            }
//        case .Failure(let error):
//            return Observable<Result<Bool>>.just(Result<Bool>.Failure(error))
//        }
//    }
//}
