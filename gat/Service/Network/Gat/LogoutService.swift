//
//  LogoutService.swift
//  gat
//
//  Created by Vũ Kiên on 05/07/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import Firebase

class LogoutService {
    
    static let shared = LogoutService()
    fileprivate let disposeBag: DisposeBag
    fileprivate let readingStatus: Repository<ReadingStatus, ReadingStatusObject>
    fileprivate let review: Repository<Review, ReviewObject>
    fileprivate let request: Repository<BookRequest, BookRequestObject>
    fileprivate let instance: Repository<Instance, InstanceObject>
    fileprivate let userNotification: Repository<UserNotification, UserNotificationObject>
    fileprivate let message: Repository<GroupMessage, GroupMessageObject>
    fileprivate let history: Repository<History, HistoryObject>
    fileprivate let userPrivate: Repository<UserPrivate, UserPrivateObject>
    fileprivate let profile: Repository<Profile, ProfileObject>
    fileprivate let bookInfo: Repository<BookInfo, BookInfoObject>
    fileprivate let bookSharing: Repository<BookSharing, BookSharingObject>
    fileprivate let post: Repository<Post, PostObject>
    
    fileprivate init() {
        self.disposeBag = DisposeBag()
        self.readingStatus = Repository<ReadingStatus, ReadingStatusObject>.shared
        self.review = Repository<Review, ReviewObject>.shared
        self.request = Repository<BookRequest, BookRequestObject>.shared
        self.instance = Repository<Instance, InstanceObject>.shared
        self.userNotification = Repository<UserNotification, UserNotificationObject>.shared
        self.message = Repository<GroupMessage, GroupMessageObject>.shared
        self.history = Repository<History, HistoryObject>.shared
        self.userPrivate = Repository<UserPrivate, UserPrivateObject>.shared
        self.profile = Repository<Profile, ProfileObject>.shared
        self.bookInfo = Repository<BookInfo, BookInfoObject>.shared
        self.bookSharing = Repository<BookSharing, BookSharingObject>.shared
        self.post = Repository.shared
    }
    
    func logout() {
        //GoogleService.shared.signOut()
        self.requestLogout()
        self.deleteAllData()
        self.gotoLogin()
    }
    
    fileprivate func requestLogout() {
        MessageService.shared.disconnect()
        try? Firebase.Auth.auth().signOut()
        UserNetworkService
            .shared
            .logout(uuid: UIDevice.current.identifierForVendor?.uuidString ?? "")
            .catchErrorJustReturn(())
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func deleteAllData() {
        UserDefaults.standard.removeObject(forKey: "password")
        UserDefaults.standard.removeObject(forKey: "email")
        self.post.deleteAll().subscribe().disposed(by: self.disposeBag)
//        self.accessToken.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.readingStatus.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.review.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.request.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.instance.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.userNotification.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.message.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.history.deleteAll().subscribe().disposed(by: self.disposeBag)
//        self.userPrivate.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.bookSharing.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.profile.deleteAll().subscribe().disposed(by: self.disposeBag)
        self.bookInfo.deleteAll().subscribe().disposed(by: self.disposeBag)
        MessageService.shared.disconnect()
        Session.shared.remove()
        UserDefaults.standard.removeObject(forKey: "hideGatupBanner")
    }
    
    fileprivate func gotoLogin() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        let storyboard = UIStoryboard.init(name: "Authentication", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: StartViewController.className)
        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = vc
    }
}
