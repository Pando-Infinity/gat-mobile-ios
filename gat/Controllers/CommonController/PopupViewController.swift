//
//  PopupViewController.swift
//  gat
//
//  Created by HungTran on 2/18/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAnalytics

/**Kiểu thông báo
 
 - Alert: Loại thông báo có 1 nút xác nhận
 - Confirm: Loại thông báo có 2 nút xác nhận*/
enum PopupData {
    case Alert(String, String, String)
    case Confirm(String, String, String, String)
}

class PopupViewController: UIViewController {
    //MARK: - UI Properties
    /**Khu vực cho các view trên giao diện*/
    @IBOutlet weak var popupTitleView: UILabel!
    @IBOutlet weak var popupMessageView: UILabel!
    /**Nếu kiểu thông báo là confirm thì hiện 2 nút bên dưới*/
    @IBOutlet weak var firstConfirmButton: UIButton!
    @IBOutlet weak var secondConfirmButton: UIButton!
    /**Nếu kiểu thông báo là alert thì hiện nút này*/
    @IBOutlet weak var alertButton: UIButton!
    
    //MARK: - Public Data Properties
    /**Khởi tạo giá trị mặc định cho thông báo*/
    var popupData: Variable<PopupData?> = Variable(nil)
    let firstConfirmButtonTapStream: Variable<Bool> = Variable(false)
    let secondConfirmButtonTapStream: Variable<Bool> = Variable(false)
    let alertButtonTapStream: Variable<Bool> = Variable(false)
    
    //MARK: - Private Data Properties
    private var disposeBag = DisposeBag()
    private var buttonClickIndex: Int = -1
    
    /**Ẩn thanh Status Bar*/
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupEvent()
    }
    
    //MARK: - Event
    private func setupEvent() {
        self.setupPopupDataChangeEvent()
        self.setupFirstConfirmButtonEvent()
        self.setupSecondConfirmButtonEvent()
        self.setupAlertButtonEvent()
    }
    
    private func setupPopupDataChangeEvent() {
        /*Đăng ký nhận hiển thị Popup. Chỉ hiển thị Popup khi cả tiêu đề và nội dung Popup khác rỗng*/
        let popupDataStream = popupData.asObservable().filter { (popupType) -> Bool in
            return popupType != nil
            }.flatMap { (popupType) -> Observable<PopupData> in
                return Observable.just(popupType!)
        }
        popupDataStream.subscribe(onNext: { [weak self] popupData in
            self?.showAnimate()
            
            switch popupData {
            case .Alert(let title, let message, let buttonTitle):
                self?.firstConfirmButton.isHidden = true
                self?.secondConfirmButton.isHidden = true
                self?.alertButton.isHidden = false
                
                /**Cài đặt tiêu đề*/
                self?.popupTitleView.text = title
                self?.popupMessageView.text = message
                
                /**Cài đặt nhãn cho nút bấm*/
                self?.alertButton.setTitle(buttonTitle, for: .normal)
            case .Confirm(let title, let message, let firstButtonTitle, let secondButtonTitle):
                /**Cài đặt hiển thị các nút bấm*/
                self?.firstConfirmButton.isHidden = false
                self?.secondConfirmButton.isHidden = false
                self?.alertButton.isHidden = true
                
                /**Cài đặt tiêu đề*/
                self?.popupTitleView.text = title
                self?.popupMessageView.text = message
                
                /**Cài đặt nhãn cho nút bấm*/
                self?.firstConfirmButton.setTitle(firstButtonTitle, for: .normal)
                self?.secondConfirmButton.setTitle(secondButtonTitle, for: .normal)
            }
        }).disposed(by: self.disposeBag)
    }
    
    private func setupFirstConfirmButtonEvent() {
        /**Cài đặt bắn sự kiện ra ngoài*/
        self.firstConfirmButton.rx.tapGesture().skip(1).asObservable().subscribe(onNext: { [weak self] _ in
            self?.removeAnimate()
            self?.buttonClickIndex = 1
            
            // Log lại sự kiện gửi lên Firebase Analytics
            if let className = self?.className {
                Analytics.logEvent("gat_button_click", parameters: [
                    "button_name": "firstConfirmButton" as NSObject,
                    "on_view": className as NSObject,
                    "from_func": "setupFirstConfirmButtonEvent()" as NSObject
                    ])
            }
        }).disposed(by: self.disposeBag)
    }
    
    private func setupSecondConfirmButtonEvent() {
        self.secondConfirmButton.rx.tapGesture().skip(1).asObservable().subscribe(onNext: { [weak self] _ in
            self?.removeAnimate()
            self?.buttonClickIndex = 2
            
            // Log lại sự kiện gửi lên Firebase Analytics
            if let className = self?.className {
                Analytics.logEvent("gat_button_click", parameters: [
                    "button_name": "secondConfirmButton" as NSObject,
                    "on_view": className as NSObject,
                    "from_func": "setupSecondConfirmButtonEvent()" as NSObject
                    ])
            }
        }).disposed(by: self.disposeBag)
    }
    
    private func setupAlertButtonEvent() {
        self.alertButton.rx.tapGesture().skip(1).asObservable().subscribe(onNext: { [weak self] _ in
            self?.removeAnimate()
            self?.buttonClickIndex = 3
            // Log lại sự kiện gửi lên Firebase Analytics
            if let className = self?.className {
                Analytics.logEvent("gat_button_click", parameters: [
                    "button_name": "alertButton" as NSObject,
                    "on_view": className as NSObject,
                    "from_func": "setupAlertButtonEvent()" as NSObject
                    ])
            }
        }).disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    private func setupUI() {
        /**Bo tròn các nút bấm*/
        firstConfirmButton.circleCorner()
        secondConfirmButton.circleCorner()
        alertButton.circleCorner()
    }
    
    /**Cài đặt hiệu animate ứng khi mở Popup*/
    func showAnimate()
    {
        self.view.backgroundColor = Gat.Color.popupShadowBackground.withAlphaComponent(0.7)
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.view.alpha = 1.0
            self?.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
    }
    
    /**Cài đặt hiệu animate ứng khi đóng Popup*/
    func removeAnimate()
    {
        self.dismiss(animated: false) { [weak self] in
            if let buttonClick = self?.buttonClickIndex {
                switch buttonClick {
                case 1:
                    self?.firstConfirmButtonTapStream.value = true
                case 2:
                    self?.secondConfirmButtonTapStream.value = true
                case 3:
                    self?.alertButtonTapStream.value = true
                default:
                    break
                }
            }
        }
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
}
