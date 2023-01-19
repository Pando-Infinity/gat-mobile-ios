//
//  AddNewBookViewController.swift
//  gat
//
//  Created by jujien on 2/19/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class AddNewBookViewController: UIViewController {

    class var segueIdentifier: String { return "showAddNew" }
    
    @IBOutlet weak var titlaLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var bookNameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var descriptionHeightConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    var titleBook: String = ""
    
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.data()
        self.event()
    }
    
    // MARK: - Data
    fileprivate func data() {
        self.sendButton.rx.tap.asObservable()
            .withLatestFrom(self.bookNameTextField.rx.text.orEmpty)
            .withLatestFrom(self.descriptionTextView.rx.text.orEmpty, resultSelector: { ($0, $1) })
            .filter { !$0.0.isEmpty }
            .map { (name, description) -> BookInfo in
                let book = BookInfo()
                book.title = name
                book.descriptionBook = description
                return book
            }
            .filter { _ in Status.reachable.value }
            .do(onNext: { [weak self] (_) in
                self?.loading(true)
            })
            .flatMap { [weak self] (book) in
                BookNetworkService.shared.addNewBook(bookInfo: book)
                    .catchError { [weak self] (error) -> Observable<()> in
                        HandleError.default.showAlert(with: error)
                        self?.loading(false)
                        return Observable.empty()
                }
            }
            .subscribe(onNext: { [weak self] (_) in
                guard let topMost = UIApplication.shared.topMostViewController() else { return }
                let action = ActionButton(titleLabel: Gat.Text.AddNewBook.OK.localized(), action: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
                AlertCustomViewController.showAlert(title: Gat.Text.AddNewBook.SUCCEEDED.localized(), message: Gat.Text.AddNewBook.MESSAGE_ADD_NEW_BOOK.localized(), actions: [action], in: topMost)
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.bookNameTextField.text = self.titleBook
        self.titlaLabel.text = Gat.Text.AddNewBook.ADD_NEW_BOOK_TITLE.localized()
        self.bookNameTextField.placeholder = Gat.Text.AddNewBook.BOOK_NAME.localized()
        self.sendButton.setTitle(Gat.Text.AddNewBook.SEND.localized(), for: .normal)
        self.descriptionTextView.text = Gat.Text.AddNewBook.DESCRIPTION_BOOK.localized()
        self.descriptionTextView
            .rx.didBeginEditing.asObservable()
            .withLatestFrom(Observable.just(self.descriptionTextView))
            .subscribe(onNext: { (textView) in
                if textView?.text == Gat.Text.AddNewBook.DESCRIPTION_BOOK.localized() {
                    textView?.text = ""
                }
                textView?.textColor = #colorLiteral(red: 0.2549019608, green: 0.2549019608, blue: 0.2549019608, alpha: 1)
            })
            .disposed(by: self.disposeBag)
        self.descriptionTextView
            .rx.didEndEditing.asObservable()
            .withLatestFrom(Observable.just(self.descriptionTextView))
            .subscribe(onNext: { (textView) in
                if textView?.text == "" {
                    textView?.text = Gat.Text.AddNewBook.DESCRIPTION_BOOK.localized()
                    textView?.textColor = #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 1)
                }
            })
            .disposed(by: self.disposeBag)
        self.bookNameTextField.rx.text.orEmpty.asObservable().map { !$0.isEmpty }.subscribe(self.sendButton.rx.isEnabled).disposed(by: self.disposeBag)
    }
    
    fileprivate func loading(_ value: Bool) {
        self.view.isUserInteractionEnabled = !value
        UIApplication.shared.isNetworkActivityIndicatorVisible = value
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backButtonEvent()
        self.changeHeightTextViewEvent()
        self.hideKeyboardEvent()
    }
    
    fileprivate func backButtonEvent() {
        self.backButton.rx.tap.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.navigationController?.popViewController(animated: true)
        })
        .disposed(by: self.disposeBag)
    }
    fileprivate func hideKeyboardEvent() {
        Observable.of(
            self.bookNameTextField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
            self.view.rx.tapGesture().when(.recognized).map { _ in },
            self.sendButton.rx.tap.asObservable()
        )
            .merge()
            .subscribe(onNext: { [weak self] (_) in
                self?.bookNameTextField.resignFirstResponder()
                self?.descriptionTextView.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func changeHeightTextViewEvent() {
        let constant = self.descriptionTextView
            .rx.text.orEmpty.asObservable().filter { !$0.isEmpty }
            .withLatestFrom(Observable.just(self.descriptionTextView))
            .map { (textView) -> CGFloat in
                let newSize = textView!.sizeThatFits(.init(width: textView!.frame.width, height: .infinity))
                return newSize.height
            }
        
        let max = UIScreen.main.bounds.height * 0.9 - 350.0
        constant.filter { $0 <= max }.subscribe(self.descriptionHeightConstraint.rx.constant).disposed(by: self.disposeBag)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}
