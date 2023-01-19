//
//  AppDelegate.swift
//  gat
//
//  Created by HungTran on 2/12/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import FBSDKCoreKit
import FBSDKLoginKit
import RealmSwift
import FacebookCore
import FacebookLogin
import GoogleMaps
import GooglePlaces
import RealmSwift
import Firebase
import UserNotifications
import TwitterKit
import Crashlytics
import Fabric
import GoogleMobileAds
import GoogleSignIn
import PanWalletSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    fileprivate var disposeBag = DisposeBag()
    fileprivate let accessTokenRepository = Repository<AccessTokenEmail, AccessTokenObject>.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.setupPanWallet()
        /*Khởi tạo Twitter*/
//        self.configTwitter()
        /**Cài đặt Firebase (Auth/Notification/Message)*/
        self.configFirebase()
        
        /*Khoi tao Google SignIn*/
        self.configGoogleSignIn()
        /*Đồng bộ lại cấu trúc cơ sở dữ liệu nếu phát hiện có thay đổi*/
        self.configRealm()
        
        //Bat dau check ket noi internet
        self.checkInternet()
        
//        Fabric.sharedSDK().debug = true
//
//        Fabric.with([Crashlytics.self])
        
        self.updateLanguage()
        
        self.navigateView()
        
        if let activityDictionary = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any] {
            let userActivity = activityDictionary.filter { $0.value is NSUserActivity }.map { $0.value as! NSUserActivity }.first!
            if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL, let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                let components = urlComponents.path.split(separator: .init("/")).map { String($0) }
                let id = components.filter { $0.isNumber }.map { Int($0)! }.first
                if let action = components.first {
                    if let editionId = id, action == "editions" {
                        let storyboard = UIStoryboard(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
                        let bookDetailViewController = storyboard.instantiateViewController(withIdentifier: "BookDetailViewController") as! BookDetailViewController
                        if let bookInfo = Repository<BookInfo, BookInfoObject>.shared.get(predicateFormat: "editionId = %@", args: [editionId]) {
                            bookDetailViewController.bookInfo.onNext(bookInfo)
                        } else {
                            let bookInfo = BookInfo()
                            bookInfo.editionId = editionId
                        }
                        let mainStoryboard = UIStoryboard(name: Gat.Storyboard.Main, bundle: nil)
                        let tabbarViewController = mainStoryboard.instantiateViewController(withIdentifier: TabBarController.className) as? TabBarController
                        self.window?.rootViewController = tabbarViewController
                        (tabbarViewController?.viewControllers?.first as? UINavigationController)?.pushViewController(bookDetailViewController, animated: true)
                    }
                    if let reviewId = id, action == "articles" {
                        let storyboard = UIStoryboard(name: "PostDetail", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: PostDetailViewController.className) as! PostDetailViewController
                        vc.presenter = SimplePostDetailPresenter(post: .init(id: reviewId, title: "", intro: "", body: "", creator: .init(profile: .init(), isFollowing: false)), imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: vc))
                        let mainStoryboard = UIStoryboard(name: Gat.Storyboard.Main, bundle: nil)
                        let tabbarViewController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController
                        self.window?.rootViewController = tabbarViewController
                        (tabbarViewController?.viewControllers?.first as? UINavigationController)?.pushViewController(vc, animated: true)
                    }
                    if let userId = id, action == "users" {
                        if Repository<UserPrivate, UserPrivateObject>.shared.get()?.id == userId {
                            let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                            let profileViewController = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                            profileViewController.isShowButton.onNext(false)
                            let mainStoryboard = UIStoryboard(name: Gat.Storyboard.Main, bundle: nil)
                            let tabbarViewController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController
                            self.window?.rootViewController = tabbarViewController
                            tabbarViewController?.selectedIndex = 2
                        } else {
                            let storyboard = UIStoryboard(name: "VistorProfile", bundle: nil)
                            let userVisitorController = storyboard.instantiateViewController(withIdentifier: "UserVistorViewController") as! UserVistorViewController
                            let userPublic = UserPublic()
                            userPublic.profile.id = userId
                            userVisitorController.userPublic.onNext(userPublic)
                            let mainStoryboard = UIStoryboard(name: Gat.Storyboard.Main, bundle: nil)
                            let tabbarViewController = mainStoryboard.instantiateViewController(withIdentifier: "Home") as? TabBarController
                            self.window?.rootViewController = tabbarViewController
                            (tabbarViewController?.viewControllers?.first as? UINavigationController)?.pushViewController(userVisitorController, animated: true)
                        }
                    }
                    if let challengeId = id, action == "challenges" {
                        let storyboard = UIStoryboard(name: "ChallengeDetailView", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "ChallengeDetailVC") as! ChallengeDetailVC
                        vc.idChallenge = challengeId
                        let mainStoryboard = UIStoryboard(name: Gat.Storyboard.Main, bundle: nil)
                        let tabbarViewController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController
                        self.window?.rootViewController = tabbarViewController
                        (tabbarViewController?.viewControllers?.first as? UINavigationController)?.pushViewController(vc, animated: true)
                    }
                }
            }
            
        }
        
        if launchOptions?[.url] == nil {
            AppLinkUtility.fetchDeferredAppLink({ (url, error) in
                guard error == nil else {
                    print("Received error while fetching deferred app link: \(error!.localizedDescription)")
                    return
                }
                
                if let url = url {
                    UIApplication.shared.open(url, options: [:], completionHandler: { (status) in
                        
                    })
                }
            })
        }
        return ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("AppDelegate, Handle URL: ", url)
        if url.absoluteString.range(of:"google") != nil{
            return GIDSignIn.sharedInstance.handle(url)
        } else if url.absoluteString.range(of:"twitterkit") != nil {
            return TWTRTwitter.sharedInstance().application(app, open: url, options: options)
        } else if url.absoluteString.range(of: "gat") != nil {
            do {
                let results = try PanWalletManager.shared.convert(url: url)
                NotificationCenter.default.post(name: .init("panwallet"), object: results)
            } catch {
                print(error)
            }
            return true
        } else {
            return ApplicationDelegate.shared.application(app, open: url, options: options)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0
        if Session.shared.isAuthenticated {
            UserNetworkService.shared.privateInfo().catchError { _ in .empty() }.flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }.subscribe().disposed(by: self.disposeBag)
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    @discardableResult
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                return false
        }
        let components = urlComponents.path.split(separator: .init("/")).map { String($0) }
        let id = components.filter { $0.isNumber }.map { Int($0)! }.first
        if let action = components.first {
            if let editionId = id, action == "editions"  {
                let storyboard = UIStoryboard(name: Gat.Storyboard.BOOK_DETAIL, bundle: nil)
                let bookDetailViewController = storyboard.instantiateViewController(withIdentifier: "BookDetailViewController") as! BookDetailViewController
                if let bookInfo = Repository<BookInfo, BookInfoObject>.shared.get(predicateFormat: "editionId = %@", args: [editionId]) {
                    bookDetailViewController.bookInfo.onNext(bookInfo)
                } else {
                    let bookInfo = BookInfo()
                    bookInfo.editionId = editionId
                }
                UIApplication.topViewController()?.navigationController?.pushViewController(bookDetailViewController, animated: true)
            }
            if let reviewId = id, action == "articles" {
                let storyboard = UIStoryboard(name: "PostDetail", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: PostDetailViewController.className) as! PostDetailViewController
                vc.presenter = SimplePostDetailPresenter(post: .init(id: reviewId, title: "", intro: "", body: "", creator: .init(profile: .init(), isFollowing: false)), imageUsecase: DefaultImageUsecase(), router: SimplePostDetailRouter(viewController: vc))
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            }
            if let userId = id, action == "users" {
                if Repository<UserPrivate, UserPrivateObject>.shared.get()?.id == userId {
                    let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
                    let profileViewController = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
                    profileViewController.isShowButton.onNext(true)
                    UIApplication.topViewController()?.navigationController?.pushViewController(profileViewController, animated: true)
                } else {
                    let storyboard = UIStoryboard(name: "VistorProfile", bundle: nil)
                    let userVisitorController = storyboard.instantiateViewController(withIdentifier: "UserVistorViewController") as! UserVistorViewController
                    let userPublic = UserPublic()
                    userPublic.profile.id = userId
                    userVisitorController.userPublic.onNext(userPublic)
                    UIApplication.topViewController()?.navigationController?.pushViewController(userVisitorController, animated: true)
                }
            }
            
            if let challengeId = id, action == "challenges" {
                let storyboard = UIStoryboard(name: "ChallengeDetailView", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "ChallengeDetailVC") as! ChallengeDetailVC
                vc.idChallenge = challengeId
                UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
            }
            return true
        }

        if let webpageUrl = URL(string: "https://gatbook.org") {
            if #available(iOS 10.0, *) {
                application.open(webpageUrl)
            } else {
                application.openURL(webpageUrl)
            }
            return false
        }

        return false
    }
    
    //MARK: - Push Notification
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        print(String(data: deviceToken, encoding: .ascii))
        Messaging.messaging().apnsToken = deviceToken
        PushNotificationService.shared.connectToFcm()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let userInfo = userInfo as? [String: Any] else {
            return
        }
        switch application.applicationState {
        case .background:
            PushNotificationService.shared.handle(userInfo: userInfo)
            break
        case .inactive:
            PushNotificationService.shared.handle(userInfo: userInfo)
            break
        case .active:
            NotificationNetworkService
                .shared
                .notifyTotal()
                .catchErrorJustReturn(0)
                .subscribe(onNext: { [weak self] (total) in
                    if let vc = self?.window?.rootViewController as? UITabBarController {
                        vc.tabBar.items?[3].badgeValue = total > 0 ? "\(total)" : nil
                    }
                })
                .disposed(by: self.disposeBag)
            break
        }
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotificationService.shared.error(error)
    }
}

extension AppDelegate {
    
    fileprivate func setupPanWallet() {
        PanWalletManager.shared.setConfig(config: .init(dappName: "GAT", dappScheme: "gat", dappUrl: "GaT.app.vn", dappLogo: nil))
    }
    
    fileprivate func checkInternet() {
        try? Status.start()
    }
    
    fileprivate func configAdmob() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
//        GADMobileAds.configure(withApplicationID: AppConfig.sharedConfig.get("admob_application_id"))
    }
    
    fileprivate func configGoogleSignIn() {
        // Initialize sign-in
        
        guard let mapKey = AppConfig.sharedConfig.config(item: "google_map_api_key") else { return }
//        GIDSignIn.sharedInstance().delegate = GoogleService.shared
        //assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        GMSServices.provideAPIKey(mapKey)
        GMSPlacesClient.provideAPIKey(mapKey)
    }
    
    /**Cập nhật cấu trúc Realm Database mỗi lần khởi động App
     (Cần tưng database_version trong AppConfig lên 1 đơn vị mỗi lần cập nhật database)*/
    fileprivate func configRealm() {
        let databaseVersion: UInt64 = AppConfig.sharedConfig.get("database_version")
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: databaseVersion,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < databaseVersion) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
    }
    
    /**Cài đặt Firebase (Auth/Notification/Message)*/
    fileprivate func configFirebase() {
        //Configure firebase
        FirebaseApp.configure()
        if Session.shared.isAuthenticated {
            FirebaseBackground.shared.registerFirebaseToken()
        }
    }
    
    
    fileprivate func navigateView() {
        if let accessToken = self.accessTokenRepository.get() {
            Session.shared.accessToken = accessToken.token
            self.accessTokenRepository.deleteAll().subscribe().disposed(by: self.disposeBag)
        }
        if Session.shared.isAuthenticated {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: TabBarController.className)
            self.window = UIWindow()
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
        } else {
            let storyboard = UIStoryboard(name: "Authentication", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: StartViewController.className)
            self.window = UIWindow()
            self.window?.rootViewController = vc
            self.window?.makeKeyAndVisible()
            
        }
    }
    
    fileprivate func updateLanguage() {
        if UserDefaults.standard.string(forKey: "language") == nil, let language = Locale.current.languageCode {
            UserDefaults.standard.set(language, forKey: "language")
        }
    }
    
}

