//
//  PopUpListBookTargetVC.swift
//  gat
//
//  Created by macOS on 8/21/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PopUpListBookTargetVC: BottomPopupViewController {
    
    @IBOutlet weak var btnExit:UIButton!
    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var reportLabel:UILabel!
    @IBOutlet weak var viewAcceptChallenge:UIView!
    @IBOutlet weak var btnAcceptChallenge:UIButton!
    @IBOutlet weak var tableViewListBookTarget:UITableView!
    
    var challenge:Challenge?
    
    private var nibListBook:UINib!
    
    override var popupHeight: CGFloat { return UIScreen.main.bounds.size.height - 100.0 }
    override var popupTopCornerRadius: CGFloat {return 20.0}
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
        self.initTableCell()
    }
    
    func setupUI(){
        self.titleLabel.text = String(format: "NUMBER_TARGET_BOOK_TITLE".localized(), challenge?.targetNumber ?? 0)
        self.cornerRadius()
        self.setupViewJoinChallenge()
        self.reportLabel.text = "ALERT_READ_BOOK_TARGET".localized()
        self.btnAcceptChallenge.setTitle("ACCEPT_CHALLENGE_TITLE".localized(), for: .normal)
    }
    
    func event(){
        
    }
    
    @IBAction func didExitTaped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func cornerRadius(){
        self.btnAcceptChallenge.cornerRadius = 9.0
    }
    
    func setupViewJoinChallenge(){
        self.viewAcceptChallenge.layer.shadowColor = UIColor.black.cgColor
        self.viewAcceptChallenge.shadowOpacity = 1
        self.viewAcceptChallenge.shadowOffset = .zero
        self.viewAcceptChallenge.shadowRadius = 10
        self.view.bringSubviewToFront(self.viewAcceptChallenge)
    }
    
    func initTableCell(){
        nibListBook = UINib.init(nibName: "BookTargetDetailTableViewCell", bundle: nil)
        self.tableViewListBookTarget.register(nibListBook, forCellReuseIdentifier: "BookTargetDetailTableViewCell")
        
        // Set delegate
        tableViewListBookTarget.delegate = self
        tableViewListBookTarget.dataSource = self
        tableViewListBookTarget.allowsSelection = true
        
        tableViewListBookTarget.rowHeight = UITableView.automaticDimension
        
        tableViewListBookTarget.backgroundColor = Colors.transparent
        tableViewListBookTarget.separatorStyle = .none
    }
    
    @IBAction func joinChallenge(_ sender: UIButton) {
            SwiftEventBus.post(
              JoinChallengeEvent.EVENT_NAME,
              sender: JoinChallengeEvent(self.challenge!.targetNumber)
            )
            self.dismiss(animated: true, completion: nil)
 
    }
}



extension PopUpListBookTargetVC:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.challenge?.editions?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookTargetDetailTableViewCell", for: indexPath) as! BookTargetDetailTableViewCell
        let challengeCell = self.challenge
        let bookArr = challengeCell?.editions
        let book = bookArr![indexPath.row]
        let img = book.imageId
        cell.imgBook.contentMode = .scaleToFill
        cell.imgBook.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: img )), placeholderImage: DEFAULT_USER_ICON)
        cell.lbNameBook.text = book.title
        cell.lbNameAuthor.text = book.author
        return cell
    }
}

extension PopUpListBookTargetVC:UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) {
            let challengeCell = self.challenge
            let bookArr = challengeCell?.editions
            let book = bookArr![indexPath.row]
            let storyboard = UIStoryboard(name: "BookDetail", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: BookDetailViewController.className) as! BookDetailViewController
            let bookInfo = BookInfo()
            bookInfo.editionId = book.editionId
            vc.bookInfo.onNext(bookInfo)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
