//
//  AlertAddBookReadingViewController.swift
//  gat
//
//  Created by jujien on 2/3/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AlertAddBookReadingViewController: BottomPopupViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var readingButton: UIButton!
    
    override var popupHeight: CGFloat { return 273.0 }
    
    override var popupTopCornerRadius: CGFloat { return 20.0 }
    
    override var popupDismissDuration: Double { return 0.2 }
    
    override var popupPresentDuration: Double { return 0.2 }
    
    override var popupShouldDismissInteractivelty: Bool { return true }
    
    override var popupDimmingViewAlpha: CGFloat { return 0.5 }
    
    fileprivate let disposeBag = DisposeBag()

    let book = BehaviorRelay<BookInfo>(value: .init())
    var show: (ReadingBookDetailViewController) -> Void = { _ in }
    
    var bookInfo: BookInfo? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }

    // MARK: - UI
    fileprivate func setupUI() {
        self.titleLabel.text = "ADD_BOOK_TITLE".localized()
        self.cancelButton.setImage(#imageLiteral(resourceName: "times"), for: .normal)
        self.messageLabel.text = "ADD_BOOKSHELF_MESSAGE".localized()
        self.addButton.setTitle("ADD_BOOK_TITLE".localized(), for: .normal)
        self.readingButton.setTitle("NO_START_READING".localized(), for: .normal)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.cancelButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: self.disposeBag)
        
        self.readingButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.dismiss(animated: true) { [weak self] in
//                let storyboard = UIStoryboard(name: "ReadingBookDetail", bundle: nil)
//                let vc = storyboard.instantiateViewController(withIdentifier: ReadingBookDetailViewController.className) as! ReadingBookDetailViewController
//                self?.show(vc)
                SwiftEventBus.post(AddBookToReadingEvent.EVENT_NAME,sender: nil)
            }
        }).disposed(by: self.disposeBag)
        self.addEvent()
    }
    
    fileprivate func addEvent() {
        self.addButton.rx.tap.asObservable()
            .flatMap { [weak self] _ in Observable.from(optional: self?.book.value) }
            .do(onNext: { [weak self] (_) in
                self?.view.isUserInteractionEnabled = false
            })
            .flatMap { [weak self] (book) -> Observable<()> in
                guard let it = self?.bookInfo else { return .empty() }
                print("Data received is editionId: \(it.editionId), bookId: \(it.bookId)")
                return InstanceNetworkService.shared.add(book: it, number: 1, sharingStatus: true)
                    .catchError { [weak self] (error) -> Observable<()> in
                        self?.view.isUserInteractionEnabled = true
                        HandleError.default.showAlert(with: error)
                        return .empty()
                }
            }
        .subscribe(onNext: { [weak self] (_) in
            // Close current dialog
            self?.view.isUserInteractionEnabled = true
            self?.dismiss(animated: true, completion: nil)
            ToastView.makeToast("ADD_BOOK_SUCCEEDED_MESSAGE_BOOKDETAIL".localized())
            
            // Send event back to BookDetailContainerController
            // to update data and show popup update progress
            SwiftEventBus.post(AddBookToBoxSuccessEvent.EVENT_NAME)
        }).disposed(by: self.disposeBag)
    }
}
