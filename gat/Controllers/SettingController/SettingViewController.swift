//
//  SettingViewController.swift
//  gat
//
//  Created by Vũ Kiên on 18/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import RxCocoa
import RxDataSources
import Firebase
import GoogleSignIn
import StoreKit

class SettingViewController: UIViewController {
    //MARK: - UI Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Public Data Properties
    fileprivate let items: BehaviorSubject<[SectionModel<String, SettingItem>]> = .init(value: [])
    fileprivate var datasource: RxTableViewSectionedReloadDataSource<SectionModel<String, SettingItem>>!
    fileprivate let disposeBag = DisposeBag()
    let googleService = GoogleService()
    var inputStatus: Bool = true
    
    //MARK: - ViewState
    override func viewDidLoad() {
        super.viewDidLoad()
        self.linkSocial()
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.titleLabel.text = Gat.Text.Setting.SETTING_TITLE.localized()
        self.getData()
//        self.getTotal()
    }
    
    // MARK: - Data
    fileprivate func getData() {
        if !Session.shared.isAuthenticated {
            self.items.onNext([
                .init(model: "", items: [
                    .init(id: 8, name: Gat.Text.Setting.CREATE_ACCOUNT_TITLE.localized(), info: "", normalImage: Gat.Image.iconGrayUser, show: true)
                ])
            ])
        }
        
        Repository<UserPrivate, UserPrivateObject>
            .shared
            .getFirst()
            .map { (userPrivate) -> [SectionModel<String, SettingItem>] in
                return [
                    SectionModel<String, SettingItem>(model: "", items: [
                        SettingItem(id: 19, name: "VIEW_MY_WALLET".localized(), info: "", normalImage: nil)
                    ]),
                    SectionModel<String, SettingItem>(model: "", items:
                        [SettingItem(id: 1,
                                     name: Gat.Text.Setting.ADD_EMAIL_AND_PASSWORD_TITLE.localized(),
                                     info: "",
                                     normalImage: Gat.Image.iconGrayEmail,
                                     show: !userPrivate.passwordFlag),
                         SettingItem(id: 2,
                                     name: Gat.Text.Setting.EDIT_USER_INFO_TITLE.localized(),
                                     info: "",
                                     normalImage: Gat.Image.iconGrayUser),
                         SettingItem(id: 3,
                                     name: Gat.Text.Setting.CHANGE_PASSWORD_TITLE.localized(),
                                     info: "",
                                     normalImage: Gat.Image.iconGrayLock,
                                     show: userPrivate.passwordFlag)
                        ]),
                    SectionModel<String, SettingItem>(model: "", items: [SettingItem(id: 10, name: "Cộng đồng GaT", info: "", enabled: true, normalImage: Gat.Image.iconFacebookHighlight, showForwardButton: true, show: true)]),
                    SectionModel<String, SettingItem>(model: "", items:
                        [SettingItem(id: 4,
                                     name: Gat.Text.Setting.FACEBOOK_TITLE,
                                     info: userPrivate.socials.filter { $0.type == .facebook && $0.statusLink == true}.first?.name ?? "",
                                     enabled: userPrivate.socials.filter { $0.type == .facebook && $0.statusLink == true }.first != nil,
                            normalImage: Gat.Image.iconFacebookHighlight,
                            disableImage: Gat.Image.iconFacebookGray),
//                         SettingItem(id: 5,
//                                     name: Gat.Text.Setting.TWITTER_TITLE,
//                                     info: userPrivate.socials.filter { $0.type == .twitter }.first?.name ?? "",
//                                     enabled: userPrivate.socials.filter { $0.type == .twitter }.first != nil,
//                            normalImage: Gat.Image.iconTwitterHighlight,
//                            disableImage: Gat.Image.iconTwitterGray),
                         SettingItem(id: 6,
                                     name: Gat.Text.Setting.GOOGLE_TITLE,
                                     info: userPrivate.socials.filter { $0.type == .google && $0.statusLink == true}.first?.name ?? "",
                                     enabled: userPrivate.socials.filter { $0.type == .google && $0.statusLink == true}.first != nil,
                            normalImage: Gat.Image.iconGoogleHighlight,
                            disableImage: Gat.Image.iconGoogleGray)
                        ]),
                    SectionModel<String, SettingItem>(model: "", items: [
                            .init(id: 11, name: Gat.Text.Bookmark.BOOKMARK_TITLE.localized(), info: "00", normalImage: #imageLiteral(resourceName: "bookmark-fill"), showForwardButton: true, show: true),
                            .init(id: 12, name: Gat.Text.Setting.READING_HISTORY.localized(), info: "", infoColor: #colorLiteral(red: 0.2549019608, green: 0.5882352941, blue: 0.7607843137, alpha: 1), normalImage: #imageLiteral(resourceName: "ic_reading_history_blue"), showForwardButton: true, show: true),
                            .init(id: 13, name: Gat.Text.BookUpdate.BOOK_UPDATE_TITLE.localized(), info: "00", normalImage: #imageLiteral(resourceName: "book_waiting"), showForwardButton: true, show: true),
                            .init(id: 14, name: Gat.Text.Setting.BOOKSHELF_GAT_UP.localized(), info: Gat.Text.Setting.BOOKSHELF_GAT_UP_DESCRIPTION.localized(), infoColor: #colorLiteral(red: 0.2549019608, green: 0.5882352941, blue: 0.7607843137, alpha: 1), normalImage: #imageLiteral(resourceName: "list-bookstop"), showForwardButton: true, show: true)
                        ]),
                    SectionModel<String, SettingItem>(model: "", items: [SettingItem(id: 9, name: Gat.Text.Language.TITLE.localized(), info: (LanguageSupport(rawValue: UserDefaults.standard.string(forKey: "language") ?? "") ?? .english).name, enabled: true, normalImage: #imageLiteral(resourceName: "language"), showForwardButton: true, show: true)]),
                    SectionModel<String, SettingItem>(model: "", items: [
                        .init(id: 15, name: Gat.Text.Setting.REVIEW_GAT.localized(), info: "", normalImage: #imageLiteral(resourceName: "star"), show: true)
                    ]),
                    SectionModel<String, SettingItem>(model: "", items: [
                        .init(id: 16, name: Gat.Text.Setting.QUESTION.localized(), info: "", normalImage: #imageLiteral(resourceName: "faq"), show: true),
                        .init(id: 17, name: Gat.Text.Setting.TERM_AND_POLICY.localized(), info: "", normalImage: #imageLiteral(resourceName: "policy"), show: true),
                        .init(id: 18, name: Gat.Text.Setting.ABOUT_US.localized(), info: "", normalImage: #imageLiteral(resourceName: "aboutGAT"), show: true)
                    ]),
                    SectionModel<String, SettingItem>(model: "", items:
                        [SettingItem(id: 7, name: Gat.Text.Setting.LOGOUT_TITLE.localized(), info: "", textColor: #colorLiteral(red: 0.9333333333, green: 0.07843137255, blue: 0.07843137255, alpha: 1), normalImage: Gat.Image.iconLogoutGray, showForwardButton: false)
                        ])
                ]
            }
            .subscribe(onNext: { [weak self] (items) in
                self?.items.onNext(items)
                self?.getTotal()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func getTotal() {
        self.getTotalBookmark()
        self.totalBookUpdate()
    }
    
    fileprivate func getTotalBookmark() {
        Observable<Int>.combineLatest(BookmarkService.shared.totalBook().catchErrorJustReturn(0), PostService.shared.totalSavedPost().catchErrorJustReturn(0), resultSelector: { $0 + $1 })
            .map { $0 <= 9 ? "0\($0)" : "\($0)" }
            .subscribe(onNext: { [weak self] (text) in
                guard let value = try? self?.items.value(), let items = value else { return }
                let section = items[4]
                section.items.first?.info = text
                self?.items.onNext(items)
            })
            .disposed(by: self.disposeBag)
    }

    fileprivate func totalBookUpdate() {
        BookUpdateSerivce.shared.totalWaiting().catchErrorJustReturn(0)
            .map { $0 <= 9 ? "0\($0)" : "\($0)" }
            .subscribe(onNext: { [weak self] (text) in
                guard let value = try? self?.items.value(), let items = value else { return }
                let section = items[4]
                section.items[2].info = text
                self?.items.onNext(items)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func linkSocial() {
        self.linkSocialFirebase()
        self.linkSocialServer()
    }
    
    fileprivate func linkSocialFirebase() {
//        self.selectSocial()
//            .flatMap {
//                FirebaseService.shared
//                    .linkBySocial(registerType: $0)
//                    .catchError { (error) -> Observable<()> in
//                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                        HandleError.default.showAlert(with: error)
//                        return Observable.empty()
//                    }
//            }
//            .subscribe()
//            .disposed(by: self.disposeBag)
    }
    
    fileprivate func linkSocialServer() {
        self.selectSocial()
            .flatMap {
                Observable<(RegisterType)>
                    .combineLatest(
                        Observable<RegisterType>.just($0),
                        UserNetworkService.shared.link(social: $0).catchError({ (error) -> Observable<()> in
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            HandleError.default.showAlert(with: error)
                            return Observable.empty()
                        }),
                        resultSelector: { (type, _) -> (RegisterType) in
                            return type
                        }
                )
            }
            .flatMap({ (type) -> Observable<()> in
                return Repository<UserPrivate, UserPrivateObject>.shared.getFirst()
                    .map({ (userPrivate) -> UserPrivate in
                        switch type {
                        case .facebook(let profile, _):
                            userPrivate.socials.append(profile)
                            break
                        case .google(let profile, _):
                            userPrivate.socials.append(profile)
                            break
                        case .twitter(let profile, _):
                            userPrivate.socials.append(profile)
                            break
                        default:
                            break
                        }
                        return userPrivate
                    })
                    .flatMap { Repository<UserPrivate, UserPrivateObject>.shared.save(object: $0) }
                
            })
            .subscribe(onNext: { [weak self] (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.getData()
            })
            .disposed(by: self.disposeBag)
        
    }
    
    //MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = Gat.Text.Setting.SETTING_TITLE.localized()
        self.setupTableView()
    }
    
    fileprivate func setupTableView() {
        self.tableView.delegate = self
        self.datasource = RxTableViewSectionedReloadDataSource<SectionModel<String, SettingItem>>.init(configureCell: { (datasource, tableView, indexPath, element) -> UITableViewCell in
            if element.id == 19 {
                let cell = tableView.dequeueReusableCell(withIdentifier: WalletTableViewCell.identifier, for: indexPath) as! WalletTableViewCell
                let formatter = NumberFormatter()
                formatter.locale = Locale(identifier: "en_US")
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 2
                cell.inAppWalletValueLable.text = "\(formatter.string(from: NSNumber(value: WalletService.shared.getBalanceInApp())) ?? "0") GAT"
                let total = WalletService.shared.totalPrice(network: .gat) + WalletService.shared.totalPrice(network: .sol)
                formatter.numberStyle = .currency
                if UserDefaults.standard.string(forKey: "wallet") == "success" {
                    cell.gatWalletValueLabel.text = formatter.string(from: NSNumber(value: total))
                    cell.gatWalletValueLabel.textColor = #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
                    cell.gatWalletValueLabel.font = .systemFont(ofSize: 24.0, weight: .bold)
                    cell.setupAction = nil
                } else {
                    cell.gatWalletValueLabel.text = "Setup wallet"
                    cell.gatWalletValueLabel.textColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
                    cell.gatWalletValueLabel.font = .systemFont(ofSize: 14.0, weight: .medium)
                    cell.setupAction = {
                        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: WalletViewController.className) as! WalletViewController
                        vc.currentIndex.accept(1)
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Gat.Cell.SettingTableViewCell, for: indexPath) as! SettingTableViewCell
                cell.settingData.value = element
                return cell
            }
            
        })
        self.items
            .flatMapLatest { (sections) -> Observable<[SectionModel<String, SettingItem>]> in
                return Observable
                    .just(
                        sections.compactMap { SectionModel<String, SettingItem>(model: $0.model, items: $0.items.filter { $0.show }) }
                )
            }
            .bind(to: self.tableView.rx.items(dataSource: self.datasource))
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.tableView
            .rx
            .modelSelected(SettingItem.self)
            .subscribe(onNext: { [weak self] (item) in
                switch item.id {
                case 1: self?.performSegue(withIdentifier: Gat.Segue.openAddEmailPassword, sender: nil)
                case 2: self?.performSegue(withIdentifier: Gat.Segue.openEditUserInfo, sender: nil)
                case 3: self?.performSegue(withIdentifier: Gat.Segue.openChangePassword, sender: nil)
                case 4:
                    if !item.info.isEmpty && item.enabled == true {
                        self?.performSegue(withIdentifier: Gat.Segue.openSocialNetworkSetting, sender: SocialType.facebook)
                    }
                case 5:
                    if !item.info.isEmpty {
                        self?.performSegue(withIdentifier: Gat.Segue.openSocialNetworkSetting, sender: SocialType.twitter)
                    }
                case 6:
                    if !item.info.isEmpty && item.enabled == true {
                        self?.performSegue(withIdentifier: Gat.Segue.openSocialNetworkSetting, sender: SocialType.google)
                    }
                case 7: LogoutService.shared.logout()
                case 8:
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    let storyboard = UIStoryboard.init(name: "Authentication", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: StartViewController.className)
                    (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = vc
                case 9: self?.performSegue(withIdentifier: LanguageViewController.segueIdentifier, sender: nil)
                case 10: UIApplication.shared.open(URL(string: "https://www.facebook.com/groups/congdonggat/")!, options: [:], completionHandler: nil)
                case 11: self?.performSegue(withIdentifier: BookmarkViewController.segueIdentifier, sender: nil)
                case 12: self?.performSegue(withIdentifier: ReadingHistoryViewController.segueIdentifier, sender: nil)
                case 13: self?.performSegue(withIdentifier: BookUpdateViewController.segueIdentifier, sender: nil)
                case 14: self?.performSegue(withIdentifier: ListBookstopOrganizationViewController.segueIdentifier, sender: nil)
                case 15:
                    if #available(iOS 10.3, *) {
                        SKStoreReviewController.requestReview()
                    } else {
                        UIApplication.shared.open(URL(string: AppConfig.sharedConfig.get("appstore_url"))!, options: [:], completionHandler: nil)
                    }
                case 16: UIApplication.shared.open(URL(string: "https://gatbook.org/faq/")!, options: [:], completionHandler: nil)
                case 17: UIApplication.shared.open(URL(string: "https://gatbook.org/term_and_policy/")!, options: [:], completionHandler: nil)
                case 18: UIApplication.shared.open(URL(string: "https://gatbook.org/about/")!, options: [:], completionHandler: nil)
                case 19:
                    let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: WalletViewController.className)
                    self?.navigationController?.pushViewController(vc, animated: true)
                default:
                    break
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func selectSocial() -> Observable<RegisterType> {
        return self.tableView.rx
            .modelSelected(SettingItem.self)
            .filter { ($0.id == 4 && $0.enabled == false) || $0.id == 5 || ($0.id == 6 && $0.enabled == false) }
            .filter { $0.info.isEmpty }
            .filter { _ in Status.reachable.value }
            .do(onNext: { (_) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1) })
            .flatMap { (item, vc) -> Observable<RegisterType> in
                switch item.id {
                case 4:
                    return FacebookService.shared
                        .login()
                        .catchError({ (error) -> Observable<String> in
                            HandleError.default.showAlert(with: error)
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            return Observable.empty()
                        })
                        .flatMap {
                            Observable<(String, SocialProfile)>
                                .combineLatest(
                                    Observable<String>.just($0),
                                    FacebookService.shared
                                        .profile()
                                        .catchError({ (error) -> Observable<SocialProfile> in
                                            HandleError.default.showAlert(with: error)
                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            return Observable.empty()
                                        }),
                                    resultSelector: { ($0, $1) }
                                )
                        }
                        .map { RegisterType.facebook($1, $0) }
                
                case 5:
                    return TwitterService
                        .shared
                        .token()
                        .catchError({ (error) -> Observable<String> in
                            HandleError.default.showAlert(with: error)
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            return Observable.empty()
                        })
                        .flatMap {
                            Observable<(String, SocialProfile)>
                                .combineLatest(
                                    Observable<String>.just($0),
                                    TwitterService.shared.profile()
                                        .catchError({ (error) -> Observable<SocialProfile> in
                                            HandleError.default.showAlert(with: error)
                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            return Observable.empty()
                                        }),
                                    resultSelector: { ($0, $1) }
                            )
                        }
                        .map { RegisterType.twitter($1, $0) }
                case 6:
                    return vc.googleService
                        .signIn(viewController: self)
                        .flatMap { _ in
                            Observable<(String, SocialProfile)>
                                .combineLatest(
                                    vc.googleService.tokenObservable
                                        .catchError({ (error) -> Observable<String> in
                                            HandleError.default.showAlert(with: error)
                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            return Observable.empty()
                                        }),
                                    vc.googleService.profileObservable
                                        .catchError({ (error) -> Observable<SocialProfile> in
                                            HandleError.default.showAlert(with: error)
                                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                            return Observable.empty()
                                        }),
                                    resultSelector: { ($0, $1) }
                            )
                        }
                        .map { RegisterType.google($1, $0) }
                default:
                    return Observable.empty()
                }
            }
    }
    
    //MARK: - Prepare Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case Gat.Segue.openSocialNetworkSetting:
            let vc = segue.destination as! SocialNetworkSettingViewController
            Repository<SocialProfile, SocialProfileObject>
                .shared
                .getFirst(predicateFormat: "type = %@", args: [(sender as! SocialType).rawValue])
                .subscribe(onNext: { (social) in
                    vc.socialProfile.onNext(social)
                })
                .disposed(by: self.disposeBag)
            break
        default: break
        }
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
    
    @IBAction func unwindToSetting(_ sender: UIStoryboardSegue) {}
}

//MARK: - Extension
extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let values = try! self.items.value()
        if values[indexPath.section].items[indexPath.row].id == 19 {
            return 152
        }
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 13.5
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
}
