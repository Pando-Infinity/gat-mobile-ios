//
//  EditInfoUserViewController.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import CoreLocation

protocol UpdateEditInfoDelegate: class {
    func update()
}

class EditInfoUserViewController: UIViewController {
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableViewTopConstrait: NSLayoutConstraint!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    let editImage = BehaviorSubject<UIImage?>(value: nil)
    let username = BehaviorSubject<String>(value: "")
    let userIdName = BehaviorSubject<String>(value: "")
    let address = BehaviorSubject<String>(value: "")
    let location = BehaviorSubject<CLLocationCoordinate2D>(value: CLLocationCoordinate2D())
    let selectCategory = BehaviorSubject<[Category]>(value: [])
    let about = BehaviorSubject<String>(value: "")
    var user: UserPrivate!
    var flagAlert:Int = 1
    fileprivate let activeSave = BehaviorSubject<Bool>(value: false)
    fileprivate let userInfoUpdate = BehaviorSubject<UserPrivate>(value: UserPrivate())
    fileprivate let disposeBag = DisposeBag()
    
    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getData()
        self.sendInfo()
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc func keyboardWillAppear() {
        //Do something here
    }

    @objc func keyboardWillDisappear() {
        //Do something here
        self.changeTableviewPosition(false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Data
    fileprivate func getData() {
        self.getDataLocal()
        self.updateInfo()
    }
    
    fileprivate func getDataLocal() {
        Repository<UserPrivate, UserPrivateObject>
            .shared
            .getFirst()
            .bind { [weak self] (user) in
                self?.user = user
                self?.user.bookstops = user.bookstops.filter { ($0.kind as? BookstopKindOrganization)?.status != nil }
                self?.userIdName.onNext(user.profile!.username)
                self?.about.onNext(user.profile!.about)
                self?.username.onNext(user.profile!.name)
                self?.selectCategory.onNext(user.interestCategory)
                self?.location.onNext(user.profile!.location)
                self?.address.onNext(user.profile!.address)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func updateImage() -> Observable<UserPrivate> {
        return self.editImage
            .compactMap { $0?.toBase64() }
            .map { (base64) -> UserPrivate in
                let user = UserPrivate()
                user.profile = Profile()
                user.profile?.imageId = base64
                return user
        }
//            .filter { $0 != nil }
//            .filter { _ in Status.reachable.value }
//            .flatMap { (image) -> Observable<String> in
//                return Observable<String>.just(image!.toBase64())
//            }
//            .flatMapLatest {
//                CommonNetworkService
//                    .shared
//                    .uploadImage(base64: $0)
//                    .catchError({ (error) -> Observable<String> in
//                        HandleError.default.showAlert(with: error)
//                        return Observable<String>.just("")
//                    })
//            }
//            .filter { !$0.isEmpty }
//            .flatMapLatest({ (imageId) -> Observable<UserPrivate> in
//                print("Image ID: \(imageId)")
//                let userPrivate = UserPrivate()
//                userPrivate.profile = Profile()
//                userPrivate.profile?.imageId = imageId
//                return Observable<UserPrivate>.just(userPrivate)
//            })
    }
    
    fileprivate func updateUsername() -> Observable<UserPrivate> {
        return self.username.flatMapLatest { (username) -> Observable<UserPrivate> in
            let userPrivate = UserPrivate()
            userPrivate.profile = Profile()
            userPrivate.profile?.name = username
            return Observable<UserPrivate>.just(userPrivate)
        }
    }
    
    fileprivate func updateUserIdName() -> Observable<UserPrivate> {
        return self.userIdName.flatMapLatest { (userIdname) -> Observable<UserPrivate> in
            let userPrivate = UserPrivate()
            userPrivate.profile = Profile()
            userPrivate.profile?.username = userIdname
            return Observable<UserPrivate>.just(userPrivate)
        }
    }
    
    fileprivate func updateAbout() -> Observable<UserPrivate> {
        return self.about.flatMapLatest { (about) -> Observable<UserPrivate> in
            let userPrivate = UserPrivate()
            userPrivate.profile = Profile()
            userPrivate.profile?.about = about
            return Observable<UserPrivate>.just(userPrivate)
        }
    }
    
    fileprivate func updateAddress() -> Observable<UserPrivate> {
        return self.address.flatMapLatest { (address) -> Observable<UserPrivate> in
            let userPrivate = UserPrivate()
            userPrivate.profile = Profile()
            userPrivate.profile?.address = address
            return Observable<UserPrivate>.just(userPrivate)
        }
    }
    
    fileprivate func updateLocation() -> Observable<UserPrivate> {
        return self.location.flatMapLatest { (location) -> Observable<UserPrivate> in
            let userPrivate = UserPrivate()
            userPrivate.profile = Profile()
            userPrivate.profile?.location = location
            return Observable<UserPrivate>.just(userPrivate)
        }
    }
    
    fileprivate func updateCategory() -> Observable<UserPrivate> {
        return self.selectCategory.flatMapLatest { (category) -> Observable<UserPrivate> in
            let userPrivate = UserPrivate()
            userPrivate.profile = Profile()
            userPrivate.interestCategory = category
            return Observable<UserPrivate>.just(userPrivate)
        }
    }
    
    fileprivate func updateInfo() {
        Observable
            .of(self.updateUsername(),self.updateUserIdName(), self.updateImage(), self.updateAddress(), self.updateLocation(), self.updateAbout(), self.updateCategory())
            .merge()
            .subscribe(onNext: { [weak self] (userPrivate) in
                guard let userInfoUpdate = try? self?.userInfoUpdate.value(), let user = userInfoUpdate, let u = self?.user else {
                    return
                }
                if user.profile == nil {
                    user.profile = Profile()
                }
                
                if !userPrivate.profile!.name.isEmpty && userPrivate.profile!.name != u.profile!.name {
                    user.profile?.name = userPrivate.profile!.name
                }
                if !userPrivate.profile!.username.isEmpty && userPrivate.profile!.username != u.profile!.name {
                    user.profile?.username = userPrivate.profile!.username
                }
                if userPrivate.profile!.about != u.profile!.about {
                    user.profile?.about = userPrivate.profile!.about
                }
                if !userPrivate.profile!.imageId.isEmpty {
                    user.profile?.imageId = userPrivate.profile!.imageId
                }
                
                if !userPrivate.profile!.address.isEmpty && userPrivate.profile!.address != u.profile!.address {
                    user.profile?.address = userPrivate.profile!.address
                }
                if userPrivate.profile!.location != CLLocationCoordinate2D() && userPrivate.profile!.location != u.profile!.location {
                    user.profile?.location = userPrivate.profile!.location
                }
                if !userPrivate.interestCategory.isEmpty && userPrivate.interestCategory != u.interestCategory {
                    user.interestCategory = userPrivate.interestCategory
                }
                user.bookstops = u.bookstops
                self?.userInfoUpdate.onNext(user)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func sendInfo() {
        Observable<(UserPrivate, Bool, UserPrivate)>
            .combineLatest(self.userInfoUpdate, self.activeSave.distinctUntilChanged(), Observable<UserPrivate>.just(self.user), resultSelector: {($0, $1, $2)})
            .do(onNext: { print($0.1) })
            .filter { (_, active, _) in active }
            .flatMap { (userUpdate, _, user) in Observable<(UserPrivate, UserPrivate)>.just((userUpdate, user)) }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
//                self?.saveButton.isUserInteractionEnabled = false
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
//                self?.tableView.isUserInteractionEnabled = false
                self?.view.isUserInteractionEnabled = false
            })
            .flatMapLatest { [weak self] (userUpdate, user) in
                Observable<(UserPrivate, UserPrivate)>
                    .combineLatest(
                        UserNetworkService.shared
                            .updateInfo(user: userUpdate)
                            .catchError { [weak self] (error) -> Observable<()> in
                                self?.activeSave.onNext(false)
                                self?.view.isUserInteractionEnabled = true
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                HandleError.default.showAlert(with: error)
                                self?.flagAlert = 1
                                self?.getDataLocal()
                                return Observable.empty()
                            },
                        Observable<UserPrivate>.just(userUpdate),
                        Observable<UserPrivate>.just(user),
                        resultSelector: { (_, userUpdate, user) -> (UserPrivate, UserPrivate) in
                            return (userUpdate, user)
                    })
            }
            .do(onNext: { (update, user) in
                if !update.profile!.name.isEmpty {
                    user.profile?.name = update.profile!.name
                }
                if !update.profile!.username.isEmpty {
                    user.profile?.username = update.profile!.username
                }
                user.profile?.about = update.profile!.about
                if !update.profile!.imageId.isEmpty {
                    user.profile?.imageId = update.profile!.imageId
                }
                if !update.profile!.address.isEmpty {
                    user.profile?.address = update.profile!.address
                }
                if update.profile!.location != CLLocationCoordinate2D() {
                    user.profile?.location = update.profile!.location
                }
                if !update.interestCategory.isEmpty {
                    user.interestCategory = update.interestCategory.compactMap { (category) in  Category.all.filter { $0.id == category.id }.first }
                }
                user.bookstops = update.bookstops
            })
            .flatMapLatest { (_, user) in Observable<UserPrivate>.just(user) }
            .flatMapLatest { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.view.isUserInteractionEnabled = true
                self?.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] (error) in
                    self?.view.isUserInteractionEnabled = true
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.activeSave.onNext(false)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.hideKeyboardWhenTappedAround()
        self.titleLabel.text = Gat.Text.EditUser.EDIT_TITLE.localized()
        self.saveButton.setTitle(Gat.Text.EditUser.SAVE_TITLE.localized(), for: .normal)
        self.cancelButton.setTitle(Gat.Text.EditUser.CANCEL_TITLE.localized(), for: .normal)
        self.saveButton.isHidden = false
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backButtonEvent()
        self.saveEvent()
    }
    
    fileprivate func saveEvent() {
//        self.saveButton
//            .rx
//            .controlEvent(.touchUpInside)
//            .bind { [weak self] in
//                self?.view.endEditing(true)
//                self?.activeSave.onNext(true)
//            }
//            .disposed(by: self.disposeBag)
        
        self.saveButton
            .rx
            .tap
            .withLatestFrom(Observable.combineLatest(self.username, self.userIdName))
            .subscribe(onNext: { (username,userIdname) in
                self.flagAlert = 2
                self.view.endEditing(true)
                if username.isEmpty {
                    let ok = ActionButton(titleLabel: "OK") { [weak self] in
                        let cell = self?.tableView.cellForRow(at: .init(row: 1, section: 0)) as? EditProfileTableViewCell
                        cell?.usernameTextField.text = Session.shared.user?.profile?.name
                    }
                    AlertCustomViewController.showAlert(title: "Error", message: "Name is empty", actions: [ok], in: self)
                }
                
                else if userIdname.isEmpty {
                    let ok = ActionButton(titleLabel: "OK") { [weak self] in
                        let cell = self?.tableView.cellForRow(at: .init(row: 1, section: 0)) as? EditProfileTableViewCell
                        cell?.usernameIdTextField.text = Session.shared.user?.profile?.username
                    }
                    AlertCustomViewController.showAlert(title: "Error", message: "UserName is empty", actions: [ok], in: self)
                }
                else {
                    self.activeSave.onNext(true)
                }
            }).disposed(by: disposeBag)
        
            
    }
    
    fileprivate func backButtonEvent() {
        self.cancelButton
            .rx
            .controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBookstopOrganization" {
            let vc = segue.destination as? BookstopOriganizationViewController
            vc?.presenter = SimpleBookstopOrganizationPresenter(bookstop: sender as! Bookstop, router: SimpleBookstopOrganizationRouter(viewController: vc))
        } 
    }
    
    func changeTableviewPosition(_ success:Bool){
        if success == true {
            self.tableViewTopConstrait.constant = -50.0
        } else {
            self.tableViewTopConstrait.constant = 0
        }
    }
}

extension EditInfoUserViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "editImageCell", for: indexPath) as! EditImageTableViewCell
            cell.controller = self
            cell.setup()
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "editProfileCell", for: indexPath) as! EditProfileTableViewCell
            cell.controller = self
            cell.changeTableViewPosition = self.changeTableviewPosition
            return cell
        }
        fatalError()
    }
}

extension EditInfoUserViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 145.0 * tableView.frame.height / 667.0
        } else if indexPath.row == 1 {
            return 270.0
        } else {
            return 60.0
        }
    }
}

extension EditInfoUserViewController: UpdateEditInfoDelegate {
    func update() {
        Repository<UserPrivate, UserPrivateObject>
            .shared
            .getFirst()
            .subscribe(onNext: { [weak self] (userPrivate) in
                self?.user = userPrivate
                self?.user.bookstops = userPrivate.bookstops.filter { ($0.kind as? BookstopKindOrganization)?.status != nil }
                self?.tableView.reloadData()
            })
            .disposed(by: self.disposeBag)

    }
    
}


