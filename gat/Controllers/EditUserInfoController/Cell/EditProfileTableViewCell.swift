//
//  EditProfileTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import CoreLocation
import RealmSwift

class EditProfileTableViewCell: UITableViewCell {

    @IBOutlet weak var usernameTitle: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var usernameIdTitle:UILabel!
    @IBOutlet weak var usernameIdTextField:UITextField!
    @IBOutlet weak var addressTitleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var favouriteCategoriesLabel: UILabel!
    @IBOutlet weak var favouriteCategoriesTitleLabel: UILabel!
    @IBOutlet weak var aboutTextView: UITextView!
    @IBOutlet weak var aboutTitleLabel: UILabel!
    @IBOutlet weak var countTextAboutLabel: UILabel!
    @IBOutlet weak var addressContainerView: UIView!
    @IBOutlet weak var favouriteContainerView: UIView!
    
    weak var controller: EditInfoUserViewController?
    var changeTableViewPosition: ((Bool) -> Void)?
    fileprivate var user: UserPrivate!
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.aboutTextView.delegate = self
        self.setup()
        self.event()
    }
    
    // MARK: - UI
    func setup() {
        self.changeTableViewPosition?(false)
        self.usernameIdTitle.text = "ID"
        self.usernameTitle.text = Gat.Text.EditUser.YOUR_NAME_PLACEHOLDER.localized()
        self.addressTitleLabel.text = Gat.Text.EditUser.ADDRESS_TITLE.localized()
        self.favouriteCategoriesTitleLabel.text = Gat.Text.EditUser.LIST_FAVOURITE_CATEGORY_TITLE.localized()
        self.aboutTitleLabel.text = Gat.Text.EditUser.ABOUT_TITLE.localized()
        Repository<UserPrivate, UserPrivateObject>
            .shared
            .getFirst()
            .filter { $0.profile != nil }
            .bind { [weak self] (user) in
                self?.user = user
                self?.usernameTextField.text = user.profile?.name
                self?.usernameIdTextField.text = user.profile?.username
                self?.addressLabel.text = user.profile?.address
                self?.favouriteCategoriesLabel.text = user.interestCategory.map { $0.title }.joined(separator: ", ")
                self?.aboutTextView.text = user.profile?.about ?? ""
                self?.countTextAboutLabel.text = user.profile!.about.isEmpty ? "0/150" : "\(user.profile!.about.count)/150"
            }
            .disposed(by: self.disposeBag)
        
    }
    
    fileprivate func showMapView() {
        let storyboard = UIStoryboard(name: "MapUserCurrentLocation", bundle: nil)
        let mapVC = storyboard.instantiateViewController(withIdentifier: "Register_SelectLocationView") as! MapViewController
        mapVC.currentLocation.onNext(user.profile!.location)
        mapVC.currentAddress.onNext(user.profile!.address)
        mapVC.delegate = self
        self.controller?.navigationController?.pushViewController(mapVC, animated: true)
    }
    
    fileprivate func showCategory() {
        let storyboard = UIStoryboard(name: "UserFavoriteCategory", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FavoriteCategoryViewController") as! FavoriteCategoryViewController
        vc.isEditingFavourite.onNext(true)
        vc.delegate = self
        vc.selectedCategory.onNext(self.user.interestCategory)
        self.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.usernameEvent()
        self.userIdnameEvent()
        self.aboutEvent()
        self.showMapViewEvent()
        self.showFavouriteCategoryEvent()
        self.hideKeyboard()
    }
    
    fileprivate func usernameEvent() {
        self.usernameTextField
            .rx
            .text
            .orEmpty
            .bind { [weak self] (text) in
                self?.controller?.username.onNext(text)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func userIdnameEvent() {
        self.usernameIdTextField.delegate = self
        self.usernameIdTextField.rx.text.orEmpty
            .filter({ (text) -> Bool in
                let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: ["^[a-z0-9_]{0,20}$"])
                return predicate.evaluate(with: text)
            })
            .bind { [weak self] (text) in
                self?.controller?.userIdName.onNext(text)
            }
            .disposed(by: self.disposeBag)
        
        self.usernameIdTextField.rx.controlEvent(.editingDidEnd).withLatestFrom(self.usernameIdTextField.rx.text.orEmpty.filter { !$0.isEmpty })
            .filter{ _ in  self.controller!.flagAlert == 1}
            .filter { $0 != Session.shared.user?.profile?.username }
            .map { (username) -> Profile in
                let profile = Profile()
                profile.username = username
                return profile
            }
        .flatMap { UserNetworkService.shared.publicInfoByUserName(user: $0).catchErrorJustReturn(.init()) }
        .filter { $0.profile.id != 0 && $0.profile.username != Session.shared.user?.profile?.username }
        .subscribe(onNext: { (user) in
            let error = ServiceError(domain: "", code: -1, userInfo: ["message": String(format: "USERNAME_ALREADY_EXIST_MESSAGE".localized(), user.profile.username)])
            HandleError.default.showAlert(with: error)
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func aboutEvent() {
        self.aboutTextView.rx.text.orEmpty.filter { $0.count <= 150 }
            .do(onNext: { [weak self] (text) in
                self?.controller?.about.onNext(text)
            })
            .map { "\($0.count)/150" }
            .bind(to: self.countTextAboutLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        self.aboutTextView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.changeTableViewPosition?(true)
            }).disposed(by: self.disposeBag)
        
    }
    
    fileprivate func showMapViewEvent() {
        self.addressContainerView
            .rx
            .tapGesture()
            .when(.recognized)
            .bind {  [weak self] (_) in
                self?.showMapView()
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func showFavouriteCategoryEvent() {
        self.favouriteContainerView
            .rx
            .tapGesture()
            .when(.recognized)
            .bind { [weak self] (_) in
                self?.showCategory()
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func hideKeyboard() {
        self.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.usernameTextField.resignFirstResponder()
                self?.aboutTextView.resignFirstResponder()
                self?.usernameIdTextField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
    }
}

extension EditProfileTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if range.length == 0 {
            return textView.text.count <= 150
        }
        return true
    }
}

extension EditProfileTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if range.length == 0 {
            let text = (textField.text ?? "") + string
            return string.range(of: "^[a-z0-9_]{1,20}$", options: .regularExpression) != nil && text.count <= 20
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension EditProfileTableViewCell: MapDelegate {
    func update(address: String) {
        self.addressLabel.text = address
        self.user.profile?.address = address
        self.controller?.address.onNext(address)
    }
    
    func update(location: CLLocationCoordinate2D) {
        self.user.profile?.location = location
        self.controller?.location.onNext(location)
    }
}

extension EditProfileTableViewCell: FavouriteCategoryDelegate {
    func update(category: [Category]) {
        self.user.interestCategory = category
        self.favouriteCategoriesLabel.text = category.map { $0.title }.joined(separator: ", ")
        self.controller?.selectCategory.onNext(category)
        
    }
}
