//
//  UIHelperViewModel.swift
//  gat
//
//  Created by HungTran on 2/25/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

enum AlertList {
    /**Title: Lỗi
     Message: message trả về từ server
     Button: "Đồng ý"*/
    case Custom
    
    /**Title: Lỗi
     Message: Không thể huỷ kết nối
     Button: "Đồng Ý"*/
    case Unlink
    
    /**Title: Thông báo
     Message: Để sử dụng chức năng này bạn phải đăng nhập vào tài khoản của mình.
     Button: "Đăng nhập", "Bỏ qua"*/
    case NeedLogin
    
    /**No GPS*/
    case NoGPS
    
    /**Title: Huỷ thay đổi
     Message: Bạn muốn huỷ bỏ thông tin đã sửa đổi?
     Button: "Có", "Không"*/
    case ModifiedData
    
    /**
     Title: Xoá sách
     Message: Bạn muốn xoá sách "name" khỏi tủ sách của mình?
     Button: "Có", "Không"*/
    case DeleteBookConfirm(String)
    
    /**
     Title: Lỗi
     Message: Để sử dụng chức năng quét mã vách bạn cần cho GaT quyền sử dụng camera.
     Button: "Cài đặt, "Bỏ qua"*/
    case NoCamera
    
    /**
     Title: Thất lạc sách
     Message: Bạn đã thử liên hệ với người mượn sách chưa?
     /n Lựa chọn thất lạc sách không thể sửa lại. Vui lòng xem xét kỹ trước khi chọn.
     Button: "Thất lạc", "Bỏ qua"
     */
    case UnreturnBookRequest
    
    /**
     Title: Huỷ yêu cầu
     Message: Bạn có chắc muốn huỷ yêu cầu mượn sách?
     Button: "Có", "Không"*/
    case CancelBookRequest
    
    /**
     Title: Từ chối yêu cầu
     Message: Bạn có chắc muốn từ chối yêu cầu mượn sách?
     Button: "Có", "Không"*/
    case RejectBookRequest
    
    /**
     Title: Lỗi
     Message: Email không tồn tại trên hệ thống
     Button: "Đồng ý*/
    case EmailNotExist
    
    /**
     Title: Thông báo
     Message: Bạn cần đăng nhập vào tài khoản {socialTyle} {socialName} để đặt lại mật khẩu.
     Button: "Đăng nhập", "Bỏ qua"*/
    case SocialLoginConfirm(SocialNetworkType, String)
    
    /**
     Title: Lỗi
     Message: Tài khoản {socialTyle} {socialName} không khớp trên hệ thống
     Button: "Đồng ý"*/
    case SocialLoginErrorAlert(SocialNetworkType, String)
    
     /**
     Title: Lỗi
     Message: Bạn cần cập nhật ứng dụng để sử dụng ứng dụng.
     Button: "Cập nhật" "Thoát"*/
    case NeedUpdateApp
}

class UIHelper {
    
    static let shared = UIHelper()
    typealias HandleAlertAction = () -> Void
    
    private var disposeBag = DisposeBag()
    private var loadingView: UIViewController?
    
    /**Hiển thị thông báo*/
    func showAlert(on: UIViewController? = nil,
                   type: AlertList,
                   message: String? = nil,
                   firstAction: @escaping HandleAlertAction = {},
                   secondAction: @escaping HandleAlertAction = {}) {
        
        /**Lấy ra nội dung thông báo tương ứng với kiểu thông báo*/
        var popupData: PopupData? = nil
        let on = on ?? UIApplication.topViewController()
        switch type {
        case .Custom:
            popupData = PopupData.Alert(
                Gat.Text.CommonError.ERROR_LOGIN_TITLE.localized(), message ?? "",
                Gat.Text.CommonError.OK_ALERT_TITLE.localized())
        case .NeedLogin:
            popupData = PopupData.Confirm(
                Gat.Text.CommonError.ERROR_LOGIN_TITLE.localized(), message ??
                Gat.Text.CommonError.LOGIN_ALERT_TITLE.localized(),
                Gat.Text.CommonError.LOGIN_ALERT_MESSAGE.localized(),
                Gat.Text.CommonError.SKIP_ALERT_TITLE.localized())
        case .Unlink:
            popupData = PopupData.Alert(
                Gat.Text.CommonError.ERROR_CONNECT_INTERNET_TITLE.localized(), message ?? Gat.Text.CommonError.ERROR_CONNECT_INTERNET_MESSAGE.localized(),
                Gat.Text.CommonError.OK_ALERT_TITLE.localized())
        case .NoGPS:
            popupData = PopupData.Confirm(Gat.Text.CommonError.ERROR_LOCATION_TITLE.localized(),
                                          Gat.Text.CommonError.ERROR_GPS_MESSAGE.localized(),
                                          Gat.Text.CommonError.SETTING_ALERT_TITLE.localized(),
                                          Gat.Text.CommonError.SKIP_ALERT_TITLE.localized())
        case .ModifiedData:
            popupData = PopupData.Confirm(Gat.Text.CommonError.CANCEL_NOTIFICATION_ALERT_TITLE.localized(),
                                          Gat.Text.CommonError.CANCEL_CHANGE_MESSAGE.localized(),
                                          Gat.Text.CommonError.YES_ALERT_TITLE.localized(),
                                          Gat.Text.CommonError.NO_ALERT_TITLE.localized())
        case .DeleteBookConfirm(_):
//            popupData = PopupData.Confirm(Gat.Text.remove_book,
//                                          String(format: Gat.Text.do_you_want_to_remove_book, bookName),
//                                          Gat.Text.yes_button,
//                                          Gat.Text.no_button)
            break
        case .NoCamera:
            popupData = PopupData.Confirm(Gat.Text.CommonError.ERROR_CAMERA_TITLE.localized(),
                                          Gat.Text.CommonError.CAMERA_ALERT_MESSAGE.localized(),
                                          Gat.Text.CommonError.SETTING_ALERT_TITLE.localized(),
                                          Gat.Text.CommonError.SKIP_ALERT_TITLE.localized())
        case .UnreturnBookRequest:
            popupData = PopupData.Confirm(Gat.Text.CommonError.LOST_BOOK_ALERT_TITLE.localized(),
                                          Gat.Text.CommonError.LOST_BOOK_MESSAGE.localized(),
                                          Gat.Text.CommonError.LOST_ALERT_TITLE.localized(),
                                          Gat.Text.CommonError.SKIP_ALERT_TITLE.localized())
        case .CancelBookRequest:
            popupData = PopupData.Confirm(Gat.Text.CommonError.CANCEL_REQUEST_ERROR_TITLE.localized(),
                                          Gat.Text.CommonError.CANCEL_REQUEST_MESSAGE.localized(),
                                          Gat.Text.CommonError.YES_ALERT_TITLE.localized(),
                                          Gat.Text.CommonError.NO_ALERT_TITLE.localized())
        case .RejectBookRequest:
            popupData = PopupData.Confirm(Gat.Text.CommonError.REJECT_ERROR_TITLE.localized(),
                                          Gat.Text.CommonError.REJECT_MESSAGE.localized(),
                                          Gat.Text.CommonError.YES_ALERT_TITLE.localized(),
                                          Gat.Text.CommonError.NO_ALERT_TITLE.localized())
        case .EmailNotExist:
            popupData = PopupData.Alert(
                Gat.Text.CommonError.ERROR_EMAIL_EXISTED_TITLE.localized(),
                Gat.Text.CommonError.EMAIL_EXISTED_MESSAGE.localized(),
                Gat.Text.CommonError.OK_ALERT_TITLE.localized())
        case .SocialLoginConfirm(let socialType, let socialName):
            var socialNetworkName = ""
            switch socialType {
            case .Facebook:
                socialNetworkName = "Facebook"
            case .Google:
                socialNetworkName = "Google"
            case .Twitter:
                socialNetworkName = "Twitter"
            default:
                break
            }
            popupData = PopupData.Confirm(Gat.Text.CommonError.SOCIAL_LOGIN_NOTIFICATION.localized(),
                                          String(format: Gat.Text.CommonError.SOCIAL_LOGIN_MESSAGE.localized(), socialNetworkName, socialName),
                                          Gat.Text.CommonError.LOGIN_ALERT_TITLE.localized(),
                                          Gat.Text.CommonError.SKIP_ALERT_TITLE.localized())
        case .SocialLoginErrorAlert(let socialType, let socialName):
            var socialNetworkName = ""
            switch socialType {
            case .Facebook:
                socialNetworkName = "Facebook"
            case .Google:
                socialNetworkName = "Google"
            case .Twitter:
                socialNetworkName = "Twitter"
            default:
                break
            }
            popupData = PopupData.Alert(
                Gat.Text.CommonError.ERROR_SOCIAL_LOGIN_TITLE.localized(),
                String(format: Gat.Text.CommonError.ERROR_SOCIAL_LOGIN_MESSAGE.localized(), socialNetworkName, socialName),
                Gat.Text.CommonError.SKIP_ALERT_TITLE.localized())
        case .NeedUpdateApp:
            popupData = PopupData.Confirm(
                Gat.Text.CommonError.UPDATE_ALERT_TITLE.localized(),
                Gat.Text.CommonError.UPDATE_MESSAGE.localized(),
                Gat.Text.CommonError.UPDATE_TITLE,
                Gat.Text.CommonError.SKIP_ALERT_TITLE.localized())
        }
        
        /**Cài đặt hiển thị màn hình Popup*/
        let popupViewController = UIStoryboard(name: "Popup", bundle: nil)
            .instantiateViewController(withIdentifier: "PopupView") as! PopupViewController
        
        /**Cài đặt dữ liệu thông báo*/
        popupViewController.popupData.value = popupData
        popupViewController.modalPresentationStyle = .overFullScreen
        popupViewController.modalTransitionStyle = .crossDissolve
        
        on?.present(popupViewController, animated: true, completion: nil)
        
        /**Cài đặt xử lý sự kiện các nút bấm*/
        guard let tmpPopupData = popupData else {
            return
        }
        
        switch tmpPopupData {
        case .Alert:
            popupViewController.alertButtonTapStream.asObservable().filter { (status) -> Bool in
                return status
                }.subscribe(onNext: { _ in
                    print("Alert Pressed")
                    firstAction()
                }).addDisposableTo(self.disposeBag)
        case .Confirm:
            popupViewController.firstConfirmButtonTapStream.asObservable().filter { (status) -> Bool in
                return status
                }.subscribe(onNext: { _ in
                    print("First Pressed")
                    firstAction()
                }).addDisposableTo(self.disposeBag)
            
            popupViewController.secondConfirmButtonTapStream.asObservable().filter { (status) -> Bool in
                return status
                }.subscribe(onNext: { _ in
                    print("Second Pressed")
                    secondAction()
                }).addDisposableTo(self.disposeBag)
        }
    }
}
