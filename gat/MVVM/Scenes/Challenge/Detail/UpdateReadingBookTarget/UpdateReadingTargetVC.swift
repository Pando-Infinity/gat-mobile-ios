//
//  UpdateReadingTarget.swift
//  gat
//
//  Created by macOS on 8/24/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class UpdateReadingTargetVC: BaseViewController {
    
    @IBOutlet weak var tableViewListBook:UITableView!
    @IBOutlet weak var lbTitle:UILabel!
    @IBOutlet weak var slider:CustomSlider!
    @IBOutlet weak var exitBtn:UIButton!
    @IBOutlet weak var lbReadingProgress:UILabel!
    
    var challenge:Challenge?
    var currentValueReading:Int = 0
    
    var nibBookReadingTarget:UINib!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
        self.initTableView()
        SwiftEventBus.onMainThread(
            self,
            name: RefreshChallengesEvent.EVENT_NAME
        ) { result in
            self.getChallengeData()
        }
    }
    
    func getChallengeData(){
        NetworkChallengeV2.shared.getChallengeByID(challenge: self.challenge!).subscribe(onNext: { (challenge) in
            print("challengeIDDDD: \(challenge.id)")
            self.challenge = challenge
            self.tableViewListBook.reloadData()
            if let challengeEdition = self.challenge?.editions {
                self.currentValueReading = challengeEdition.compactMap { $0.userRelation }.map { $0.readingStatusId }.reduce(0) { (result, readingStatusId) -> Int in
                    var result = result
                    if readingStatusId == 0 {
                        result += 1
                    }
                    return result
                }
            }
            self.slider.value = Float(self.currentValueReading)
            if self.slider.value == 0 {
                self.slider.setThumbImage(UIImage(), for: .normal)
            }
            self.setupLbProgressSlider()
            }).disposed(by: disposeBag)
    }
    
    func setupUI(){
        self.lbTitle.text = "UPDATE_READING_TARGET_TITLE".localized()
        
        self.tableViewListBook.cornerRadius(radius: 10.0)
        self.setupSlider()
    }
    
    func event(){
        self.exitBtnEvent()
    }
    
    func setupSlider(){
        self.slider.setThumbImage(UIImage.init(named: "progressReading"), for: .normal)
        self.slider.minimumTrackTintColor = UIColor.init(hex6: 0xFFE186, alpha: 1.0)
        self.slider.maximumTrackTintColor = UIColor.white
        self.slider.isUserInteractionEnabled = false
        
        self.slider.maximumValue = Float(self.challenge?.editions?.count ?? 0)
        self.slider.minimumValue = 0
        
        if let challengeEdition = self.challenge?.editions {
            self.currentValueReading = challengeEdition.compactMap { $0.userRelation }.map { $0.readingStatusId }.reduce(0) { (result, readingStatusId) -> Int in
                var result = result
                if readingStatusId == 0 {
                    result += 1
                }
                return result
            }
        }
        
        self.slider.value = Float(self.currentValueReading)
        if self.slider.value == 0 {
            self.slider.setThumbImage(UIImage(), for: .normal)
        }
        print("VALUE: \(self.slider.value)")
        
        self.setupLbProgressSlider()
        
    }
    
    func setupLbProgressSlider(){
        let string = String(format: "%d / %d".localized(), self.currentValueReading ,Int(self.slider.maximumValue))
        let attributedString = NSMutableAttributedString(string: string, attributes: [
          .font: UIFont.systemFont(ofSize: 16.0, weight: .bold),
          .foregroundColor: UIColor(red: 52.0 / 255.0, green: 73.0 / 255.0, blue: 95.0 / 255.0, alpha: 1.0)
        ])
        attributedString.addAttribute(.foregroundColor, value: UIColor(red: 232.0 / 255.0, green: 75.0 / 255.0, blue: 53.0 / 255.0, alpha: 1.0), range: (string as NSString).range(of: String(Int(self.slider.maximumValue))))
        self.lbReadingProgress.attributedText = attributedString
    }
    
    func exitBtnEvent(){
        self.exitBtn
            .rx
            .controlEvent(.touchUpInside)
            .bind{ [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
    }
    
    func initTableView(){
        nibBookReadingTarget = UINib.init(nibName: "BookTargetReadingProgressTableViewCell", bundle: nil)
        self.tableViewListBook.register(nibBookReadingTarget, forCellReuseIdentifier: "BookTargetReadingProgressTableViewCell")
        
        self.tableViewListBook.delegate = self
        self.tableViewListBook.dataSource = self
        self.tableViewListBook.allowsSelection = true
        tableViewListBook.separatorStyle = .none
        tableViewListBook.backgroundColor = .white
    }
    
    fileprivate func showBookDetailWhenTapUpdateReadingCell(_ bookinfo:Book){
        let storyboard = UIStoryboard(name: "BookDetail", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: BookDetailViewController.className) as! BookDetailViewController
        let book = BookInfo()
        book.editionId = bookinfo.editionId
        vc.bookInfo.onNext(book)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func onAddBookToReadingEvent(readingBook: Reading) {
        self.openReadingProgessPopup(readingBook.edition?.editionId ?? 0, readingBook.readingId, readingBook.pageNum, readingBook.readPage, readingBook.startDate, readingBook.completeDate, readingBook.edition?.title ?? "", readingBook.readingStatusId)
    }
    
    private func openReadingProgessPopup(
        _ editionId: Int,
        _ readingId: Int?,
        _ numPage: Int,
        _ curentPage: Int,
        _ startDate: String,
        _ completeDate: String,
        _ bookTitle: String,
        _ readingStatusId: Int) {
        
        if readingStatusId == 1 {
            guard let popupVC = self.getViewControllerFromStorybroad(
                storybroadName: "ReadingProcessView",
                identifier: "ReadingProcessVC"
                ) as? ReadingProcessVC else { return }
            //popupVC.readingBook = self.viewModel.reading(index: row)
            if readingId ?? -1 > 0 {
                popupVC.editionId = editionId
                popupVC.readingId = readingId
                popupVC.maxSlider = numPage
                popupVC.current = curentPage
                popupVC.startDate = startDate
                popupVC.completeDate = completeDate
                popupVC.bookTitle = bookTitle
            } else {
                popupVC.editionId = editionId
                popupVC.bookTitle = bookTitle
                popupVC.maxSlider = numPage
            }
            popupVC.delegate = self
            let navigation = PopupNavigationController(rootViewController: popupVC)
            navigation.navigationBar.isHidden = true
            present(navigation, animated: true, completion: nil)
        } else {
            guard let popupVC = self.getViewControllerFromStorybroad(
                storybroadName: "ReadingProcessView",
                identifier: ReviewProcessViewController.className
                ) as? ReviewProcessViewController else { return }
            let book = BookInfo()
            book.editionId = editionId
            book.title = bookTitle
            popupVC.book.accept(book)
            popupVC.delegate = self
            let navigation = PopupNavigationController(rootViewController: popupVC)
            navigation.navigationBar.isHidden = true
            present(navigation, animated: true, completion: nil)
        }
    }
}

extension UpdateReadingTargetVC: ReadingProcessDelegate {
    func readingProcess(readingProcess: ReviewProcessViewController, open post: Post) {
        readingProcess.navigationController?.dismiss(animated: true, completion: nil)
        let step = StepCreateArticleViewController()

        let storyboard = UIStoryboard(name: "CreateArticle", bundle: nil)
        let createArticle = storyboard.instantiateViewController(withIdentifier: CreatePostViewController.className) as! CreatePostViewController
        createArticle.presenter = SimpleCreatePostPresenter(post: post, imageUsecase: DefaultImageUsecase(), router: SimpleCreatePostRouter(viewController: createArticle, provider: step))
        step.add(step: .init(controller: createArticle, direction: .forward))
        self.navigationController?.pushViewController(step, animated: true)
    }
    
    func update(post: Post) {}
}

extension UpdateReadingTargetVC:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.challenge?.editions?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookTargetReadingProgressTableViewCell", for: indexPath) as! BookTargetReadingProgressTableViewCell
        let challengeCell = self.challenge
        let bookArr = challengeCell?.editions
        let book = bookArr![indexPath.row]
        let img = book.imageId
        cell.book.accept(book)
        let userReading = Reading()
        userReading.edition = Book()
        userReading.edition?.editionId = book.editionId
        userReading.readingId = book.userRelation?.readingId ?? -1
        userReading.readingStatusId = book.userRelation?.readingStatusId ?? 1
        userReading.pageNum = book.userRelation?.pageNum ?? 0
        if userReading.pageNum == 0 {
            userReading.pageNum = book.numberPage
        }
        userReading.readPage = book.userRelation?.readPage ?? 0
        userReading.startDate = book.userRelation?.startDate ?? ""
        cell.reading = userReading
        cell.setUIByStatusReading(reading: userReading)
        cell.setupProgressBar(reading: userReading)
        cell.imgBook.contentMode = .scaleToFill
        cell.imgBook.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: img )), placeholderImage: DEFAULT_USER_ICON)
        cell.lbNameBook.text = book.title
        cell.lbNameAuthor.text = book.author
        cell.startHandle = { [weak self] (reading) in
            self!.onAddBookToReadingEvent(readingBook: reading)
        }
        cell.tapImgBook = { [weak self] success in
            if success == true {
                self?.showBookDetailWhenTapUpdateReadingCell(book)
            }
        }
        return cell
    }
}

extension UpdateReadingTargetVC:UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let challengeCell = self.challenge
        let bookArr = challengeCell?.editions
        let book = bookArr![indexPath.row]
        let userReading = Reading()
        userReading.edition?.editionId = book.editionId
        userReading.readingId = book.userRelation?.readingId ?? -1
        userReading.readingStatusId = book.userRelation?.readingStatusId ?? 1
        userReading.pageNum = book.userRelation?.pageNum ?? 0
        userReading.readPage = book.userRelation?.readPage ?? 0
        userReading.startDate = book.userRelation?.startDate ?? ""

        print("arrEdition[indexPath.row].userRelation!.readingStatusId: \(book.userRelation?.readingStatusId)")
        print("arrEdition[indexPath.row].userRelation!.pageNum: \(book.userRelation?.pageNum)")
        print("arrEdition[indexPath.row].userRelation!.readingId: \(book.userRelation?.readingId)")
        if userReading.readingId > 1 {
            self.onAddBookToReadingEvent(readingBook: userReading)
        }
    }
}


class CustomSlider: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let point = CGPoint(x: bounds.minX, y: bounds.midY - 5)
        return CGRect(origin: point, size: CGSize(width: bounds.width, height: 15))
    }
}

enum StatusReading:Int{
    case notReading = 2
    case isReading = 1
    case doneReading = 0
}
