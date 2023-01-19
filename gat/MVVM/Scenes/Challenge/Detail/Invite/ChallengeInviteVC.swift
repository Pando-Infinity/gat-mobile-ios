//
//  ChallengeInviteVC.swift
//  gat
//
//  Created by macOS on 8/18/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ChallengeInviteVC: BottomPopupViewController {
    
    struct DefaultParam {
        var challenge: Challenge?
        var pageNum: Int
        var pageSize: Int = 10
        var text: String = ""
    }
    
    @IBOutlet weak var inviteTitle:UILabel!
    @IBOutlet weak var exitBtn:UIButton!
    @IBOutlet weak var inviteBtn:UIButton!
    @IBOutlet weak var searchBar:UISearchBar!
    @IBOutlet weak var listPeppleInviteTableView:UITableView!
    
    let user: BehaviorSubject<Profile> = .init(value: UserPrivate().profile!)
    fileprivate let param: BehaviorRelay<DefaultParam> = .init(value: .init(challenge: nil, pageNum: 1))
    fileprivate var listFollow:[UserPublic] = []
    var challenge:Challenge?
    
    override var popupHeight: CGFloat { return UIScreen.main.bounds.size.height - 100.0 }
    override var popupTopCornerRadius: CGFloat {return 20.0}
    
    var passTap:((Bool) -> Void)?
    var passId:Int?
    
    private var nibListInvite: UINib!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.param.accept(.init(challenge: self.challenge, pageNum: 1))
        self.getDataSearch()
        self.event()
        self.setupUI()
        self.initTableView()
    }
    
    private func initTableView(){
        nibListInvite = UINib.init(nibName: "InvitePersonTableViewCell", bundle: nil)
        self.listPeppleInviteTableView.register(nibListInvite, forCellReuseIdentifier: "InvitePersonTableViewCell")
        
        // Set delegate
        listPeppleInviteTableView.delegate = self
        listPeppleInviteTableView.dataSource = self
        listPeppleInviteTableView.allowsSelection = true
        
        listPeppleInviteTableView.rowHeight = UITableView.automaticDimension
        
        listPeppleInviteTableView.backgroundColor = Colors.transparent
        listPeppleInviteTableView.separatorStyle = .none
    }
    
    func setupUI(){
        self.setupSearchBar()
        self.hideKeyboardWhenTappedAround()
    }
    
    func setupSearchBar(){
        self.searchBar.backgroundColor = .white
        self.searchBar.backgroundImage = UIImage()
        self.searchBar.barTintColor = UIColor(red: 241.0/255.0, green: 245.0/255.0, blue: 247.0/255.0, alpha: 1.0)
        self.searchBar.tintColor = .white
        self.searchBar.placeholder = "SEARCH_TITLE".localized()
        self.inviteTitle.text = "INVITE_FRIEND_TITLE".localized()
        self.inviteBtn.isHidden = true
    }
    
    func event(){
        self.passTap = { [weak self] success in
            if success == true {
                self!.dismiss(animated: true) {
                    self?.openProfileWhenTapImgUser(userId: (self?.passId)!)
                }
            }
        }
    }
    
    @IBAction func didExitTaped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
//MARK: - DATA
    func getDataSearch(){
        self.searchBar.rx.text.orEmpty.withLatestFrom(Observable.just(self)) { (text, vc) -> DefaultParam in
            return .init(challenge: vc.challenge, pageNum: 1, text: text)
        }
        .subscribe(onNext: self.param.accept)
        .disposed(by: self.disposeBag)
        
        
        
        self.param
            .filter { $0.challenge != nil }
            .flatMap { (param) -> Observable<[UserPublic]> in
                return UserInviteToChallenge.shared
                    .listSearchInvitable(challenge: param.challenge!, page: param.pageNum, username: param.text)
                    .catchError { (error) -> Observable<[UserPublic]> in
                        return .empty()
                }
        }
        .withLatestFrom(Observable.just(self)) { (results, vc) -> [UserPublic] in
            var list = vc.listFollow
            if vc.param.value.pageNum == 1 {
                list = results
            } else {
                list.append(contentsOf: results)
            }
            return list
        }
        .subscribe(onNext: { [weak self] (results) in
            self?.listFollow = results
            self?.listPeppleInviteTableView.reloadData()
            
        }).disposed(by: self.disposeBag)
    }
    
    func openProfileWhenTapImgUser(userId:Int){
        if Repository<UserPrivate, UserPrivateObject>.shared.get()?.id == userId {
            let user = UserPrivate()
            user.profile!.id = userId
            let storyboard = UIStoryboard(name: "PersonalProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: ProfileViewController.className) as! ProfileViewController
            vc.isShowButton.onNext(true)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)

        } else {
            let user = UserPublic()
            user.profile = Profile()
            user.profile.id = userId
            let storyboard = UIStoryboard(name: "VistorProfile", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: UserVistorViewController.className) as! UserVistorViewController
            vc.userPublic.onNext(user)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        let transition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if self.listPeppleInviteTableView.contentOffset.y >= (self.listPeppleInviteTableView.contentSize.height - self.listPeppleInviteTableView.frame.height) {
            if transition.y < -70 {
                var param = self.param.value
                param.pageNum += 1
                self.param.accept(param)
            }
        }
    }
}


//MARK: - DATA SOURCE TABLEVIEW
extension ChallengeInviteVC:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listFollow.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InvitePersonTableViewCell", for: indexPath) as! InvitePersonTableViewCell
        let profile = self.listFollow[indexPath.row].profile
        cell.imgUser.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile.imageId)), placeholderImage: DEFAULT_USER_ICON)
        cell.lbNameUser.text = profile.name
        if listFollow[indexPath.row].invited == true {
            cell.flagInvite.accept(2)
        } else {
            cell.flagInvite.accept(1)
        }
        cell.startHandle = { [weak self] success in
            if success == true {
                UserInviteToChallenge.shared.inviteUserById(challenge: (self?.challenge)!, userIds: [(self?.listFollow[indexPath.row].profile.id)!]).subscribe(onNext: { (_) in
                    self?.listFollow[indexPath.row].invited = true
                    self?.listPeppleInviteTableView.reloadData()
                }).disposed(by: self!.disposeBag)
            }
        }
        cell.tapImgUser = { [weak self] success in
            if success == true {
                self?.passTap?(true)
                self?.passId = profile.id
            }
        }
        return cell
    }
}

//MARK: - DELEGATE TABLEVIEW
extension ChallengeInviteVC:UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }
}
