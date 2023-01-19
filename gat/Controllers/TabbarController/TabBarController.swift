//
//  TabBarController.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import CoreLocation

class TabBarController: UITabBarController {
    
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        InstanceBackground.shared.configure().subscribe().disposed(by: self.disposeBag)
        ReviewBackground.shared.configure().subscribe().disposed(by: self.disposeBag)
        PushNotificationService.shared.register()
        self.getLocation()
        if !UserDefaults.standard.bool(forKey: "removeOldGroupMessage3") {
            let realm = try? Realm()
            if let result = realm?.objects(GroupMessageObject.self) {
                do {
                    try realm?.write {
                        realm?.delete(result)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            UserDefaults.standard.set(true, forKey: "removeOldGroupMessage3")
            
        }
        self.tabBar.becomeFirstResponder()
        self.event()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getCountNotification()
    }

    //MARK: - Data
    fileprivate func updateLocalMessage() {
        self.deleteOldMessage()
    }
    
    fileprivate func deleteOldMessage() {
        let now = Date()
        let lastWeek = Date(timeIntervalSince1970: now.timeIntervalSince1970 - 604_800)
        Repository<Message, MessageObject>.shared.removeAll(predicate: .init(format: "sendDate < %@ AND isRead == %@", argumentArray: [lastWeek, true])).subscribe().disposed(by: self.disposeBag)
        
    }
    
    func getCountNotification() {
        guard Session.shared.isAuthenticated else { return }
        NotificationNetworkService.shared.notifyTotal().catchErrorJustReturn(0)
            .subscribe(onNext: { [weak self] (total) in
                self?.tabBar.items?[3].badgeValue = total > 0 ? "\(total)" : nil
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getLocation() {
        Repository<UserPrivate, UserPrivateObject>
            .shared
            .getFirst()
            .flatMapFirst { (userPrivate) -> Observable<CLLocationCoordinate2D> in
                if userPrivate.profile!.address.isEmpty && userPrivate.profile!.location == CLLocationCoordinate2D() {
                    return LocationManager.manager.location
                }
                return Observable.empty()
            }
            .elementAt(0)
            .flatMapLatest { (location) -> Observable<(CLLocationCoordinate2D, String)> in
                return Observable<(CLLocationCoordinate2D, String)>.combineLatest(Observable<CLLocationCoordinate2D>.just(location), GoogleMapService.default.address(in: location), resultSelector: { ($0, $1) })
            }
            .filter { (_, address) in !address.isEmpty }
            .map { (location, address) -> UserPrivate in
                let userPrivate = UserPrivate()
                userPrivate.profile = Profile()
                userPrivate.profile?.address = address
                userPrivate.profile?.location = location
                return userPrivate
            }
            .flatMapLatest {
                Observable<(CLLocationCoordinate2D, String, ())>
                    .combineLatest(
                        Observable<CLLocationCoordinate2D>.just($0.profile!.location),
                        Observable<String>.just($0.profile!.address),
                        UserNetworkService.shared.updateInfo(user: $0),
                        resultSelector: { ($0, $1, $2) }
                    )
            }
            .map { (location, address, _ ) in (location, address) }
            .flatMapLatest {
                Observable<(UserPrivate, CLLocationCoordinate2D, String)>
                    .combineLatest(
                        Repository<UserPrivate, UserPrivateObject>.shared.getFirst(),
                        Observable<CLLocationCoordinate2D>.just($0),
                        Observable<String>.just($1),
                        resultSelector: {($0, $1, $2)}
                    )
            }
            .map { (userPrivate, location, address) -> UserPrivate in
                userPrivate.profile?.address = address
                userPrivate.profile?.location = location
                return userPrivate
            }
            .flatMapLatest { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
            .subscribe()
            .disposed(by: self.disposeBag)
        
    }
    
    // MARK: - Event
    fileprivate func event() {
//        self.permissionLocation()
//        self.checkVersion()
        self.configMessage()
    }
    
    fileprivate func configMessage() {
        guard Session.shared.isAuthenticated else { return }
        MessageService.shared.configure()
    }
    
    fileprivate func permissionLocation() {
        LocationManager
            .manager
            .permission
            .asObservable()
            .bind {  (permission) in
                guard let vc = UIApplication.topViewController(), !permission else {
                    return
                }
                let actionCancel = ActionButton(titleLabel: Gat.Text.Home.CANCEL_ALERT_TITLE.localized(), action: nil)
                let actionSetting = ActionButton(titleLabel: Gat.Text.Home.SETTING_ALERT_TITLE.localized(), action: {
                    guard let url = URL(string: Gat.Prefs.OPEN_PRIVACY) else {
                        return
                    }
                    guard UIApplication.shared.canOpenURL(url) else {
                        return
                    }
                    UIApplication.shared.open(url, options: [:], completionHandler: { (status) in
                        
                    })
                })
                AlertCustomViewController.showAlert(title: Gat.Text.Home.ERROR_ALERT_TITLE.localized(), message: Gat.Text.CommonError.ERROR_GPS_MESSAGE.localized(), actions: [actionCancel, actionSetting], in: vc)
            }
            .disposed(by: self.disposeBag)
    }

    fileprivate func checkVersion() {
        Observable<String>
            .from(optional: Bundle.main.releaseVersionNumber)
            .filter { !$0.isEmpty }
            .filter { _ in Status.reachable.value }
            .flatMapLatest { CommonNetworkService.shared.check(version: $0).catchErrorJustReturn(false) }
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (status) in
                self?.showAlert(with: status)
            })
            .disposed(by: self.disposeBag)
    }
    
    
    //MARK: - UI
    fileprivate func showAlert(with status: Bool) {
        guard status else {
            return
        }
        let action: ActionButton = .init(titleLabel: Gat.Text.CommonError.OK_ALERT_TITLE.localized()) {
            var appStoreUrl: String = AppConfig.sharedConfig.get("appstore_url")
            appStoreUrl = appStoreUrl.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
            guard let url = URL(string: appStoreUrl) else {
                return
            }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    exit(0)
                })
            } else {
                UIApplication.shared.openURL(url)
                exit(0)
            }
        }
        AlertCustomViewController.showAlert(title: Gat.Text.CommonError.UPDATE_TITLE.localized(), message: Gat.Text.CommonError.UPDATE_MESSAGE.localized(), actions: [action], in: self)
    }
}

extension UIResponder {
    var responderChain: String {
        guard let next = next else {
            return String(describing: Self.self)
        }
        return String(describing: Self.self) + " -> " + next.responderChain
    }
}
