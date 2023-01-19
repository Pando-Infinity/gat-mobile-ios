//
//  AddEmailPasswordViewController.swift
//  gat
//
//  Created by HungTran on 5/6/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift
import Firebase
import RxCocoa

class AddEmailPasswordViewController: UIViewController {
    //MARK: - UI Properties
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Private Data Properties
    private var disposeBag = DisposeBag()
//    private var isModified: Variable<Bool> = Variable(false)
//    /**Biến đánh dấu trạng thái bật/tắt các input của giao diện*/
//    private var inputStatus: Variable<Bool> = Variable(true)
    
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupEvent()
        self.setupUI()
    }
    
    //MARK: - Event
    private func setupEvent() {
        self.setupBackButtonEvent()
        self.setupIsModifiedEvent()
        self.setupSaveButtonEvent()
    }
    
    private func setupBackButtonEvent() {
        self.backButton
            .rx
            .tap.asObservable()
            .withLatestFrom(self.email.rx.text.orEmpty)
            .withLatestFrom(self.password.rx.text.orEmpty, resultSelector: { ($0, $1) })
            .map { !$0.isEmpty || !$1.isEmpty }
            .subscribe(onNext: { [weak self] (status) in
                self?.navigationController?.popViewController(animated: true)
//                if status {
//
//                } else {
//                    self?.navigationController?.popViewController(animated: true)
//                }
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setupIsModifiedEvent() {
        Observable<Bool>
            .combineLatest(self.email.rx.text.orEmpty.asObservable(), self.password.rx.text.orEmpty.asObservable(), resultSelector: { !$0.isEmpty && !$1.isEmpty })
            .subscribe(self.saveButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
    }
    
    private func setupSaveButtonEvent() {
        /**Lấy dữ liệu và cập nhật lên server sử dụng api*/
        self.saveButton
            .rx
            .tap.asObservable()
            .withLatestFrom(self.email.rx.text.orEmpty)
            .withLatestFrom(self.password.rx.text.orEmpty, resultSelector: { ($0, $1) })
            .filter { !$0.isEmpty && !$1.isEmpty }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.view.isUserInteractionEnabled = false
            })
            .flatMap { [weak self] (email, password) in
                UserNetworkService
                    .shared
                    .add(email: email, andPassword: password)
                    .catchError { [weak self] (error) -> Observable<String> in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                        self?.view.isUserInteractionEnabled = false
                        HandleError.default.showAlert(with: error)
                        return Observable.empty()
                    }
            }
            .flatMap({ [weak self] (_) -> Observable<()> in
                return Repository<UserPrivate, UserPrivateObject>
                    .shared
                    .getFirst()
                    .do(onNext: { [weak self] (userPrivate) in
                        userPrivate.profile?.email = self?.email.text ?? ""
                        userPrivate.passwordFlag = true
                    })
                    .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            })
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self?.view.isUserInteractionEnabled = false
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - UI
    private func setupUI() {
        self.titleLabel.text = Gat.Text.AddEmailAndPassword.ADD_EMAIL_AND_PASSWORD_TITLE.localized()
        self.email.attributedPlaceholder = .init(string: Gat.Text.AddEmailAndPassword.ADD_EMAIL_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.password.attributedPlaceholder = .init(string: Gat.Text.AddEmailAndPassword.PASSWORD_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.setupShowCurrentLoggedInEmailUI()
        
        Observable<Bool>
            .combineLatest(self.email.rx.text.orEmpty.asObservable(), self.password.rx.text.orEmpty.asObservable(), resultSelector: { ($0.isEmpty && $1.isEmpty ) })
            .subscribe(onNext: { [weak self] (status) in
                self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = status
            })
            .disposed(by: self.disposeBag)
        
        /**Kích hoạt swipe*/
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    private func setupShowCurrentLoggedInEmailUI() {
        Repository<UserPrivate, UserPrivateObject>
            .shared
            .getFirst()
            .map { $0.profile?.email }
            .subscribe(self.email.rx.text)
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
}

//MARK: - Extension
extension AddEmailPasswordViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
