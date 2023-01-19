//
//  ReadingBookDetailVC.swift
//  gat
//
//  Created by Hung Nguyen on 2/19/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import Cosmos
import RxSwift

protocol ReadingProcessDelegate: class {
    func readingProcess(readingProcess: ReviewProcessViewController, open post: Post)
        
    func update(post: Post)
}

class ReadingProcessVC: UIViewController {
    
    var bookTitle: String = ""
    var editionId: Int = 0
    var readingId: Int?
    var totalPage: Int = 0
    
    var minSlider: Int = 0
    var maxSlider: Int = 0
    var current: Int = 0
    
    var startDate: String = ""
    var completeDate: String = ""
    // Reading stsatus let me know one book is reading done or not
    // If readingStatus = 0 means read complete
    // If readingStatus = 1 means book is reading
    var readingStatus: Int = 1
    
    weak var delegate: ReadingProcessDelegate?
    
    private let stepSlider: Float = 1.0
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var tfProcess: UITextField!
    @IBOutlet weak var tfTotalPage: UITextField!
    @IBOutlet weak var lbConfirm: UILabel!
    @IBOutlet weak var btnUpdateProgress: UIButton!
    
    private var viewModel: ReadingBookViewModel!
    
    private let getReview = PublishSubject<Int>() // Int is editionId
    private let addReading = PublishSubject<UpdateReadingPost>()
    private let updateReading = PublishSubject<UpdateReadingPost>()
    private let disposeBag = DisposeBag()
        
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init View
        initView()
        
        //Bind ViewModel
        bindViewModel()
        
        changeFrameWhenKeyboardShow()
        
        //set up localized string
        self.setUpLocalizedString()
    }
    
    private func changeFrameWhenKeyboardShow(){
        Observable.of(
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification),
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
        ).merge()
            .withLatestFrom(Observable.just(self), resultSelector: { ($0, $1)})
            .subscribe(onNext: { (notification, vc) in
                guard let frame = vc.navigationController?.view.frame else { return }
                if let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue, notification.name == UIResponder.keyboardWillShowNotification {
                    var rect = value.cgRectValue
                    if #available(iOS 11.0, *) {
                        let window = UIApplication.shared.keyWindow
                        let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
                        rect.size.height = rect.height - bottomPadding
                        if bottomPadding != .zero {
                            rect.size.height = rect.height + 40.0
                        }
                    }
                    let changeY = rect.height - (vc.tfProcess.frame.origin.y + vc.tfProcess.frame.height)
                    vc.navigationController?.view.frame.origin.y = frame.origin.y - changeY
                } else if notification.name == UIResponder.keyboardWillHideNotification {
                    vc.navigationController?.view.frame.origin.y = UIScreen.main.bounds.height - frame.height
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setUpLocalizedString(){
        self.titleLabel.text = "UPDATE_PROGRESS".localized()
        self.lbTitle.text = "REMIND_USER_UPDATE_PROGRESS".localized()
        self.lbConfirm.text = "CONFIRM_READ".localized()
        self.btnUpdateProgress.setTitle("UPDATE_ALERT_TITLE".localized(), for: .normal)
    }
    
    private func initView() {
        // Disable slide down to dismiss popup
        // to avoid conflict when slide slider
        tfTotalPage.borderStyle = .none
        tfProcess.borderStyle = .none
        tfProcess.borderWidth = 1.0
        tfProcess.borderColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        tfProcess.cornerRadius = 4.0
        tfTotalPage.borderWidth = 1.0
        tfTotalPage.borderColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        tfTotalPage.cornerRadius = 4.0
        view.gestureRecognizers?.removeAll()

        lbTitle.text = "HOW_MANY_PAGES_HAVE_READ".localized()
        
        self.tfTotalPage.isUserInteractionEnabled = self.maxSlider == 0
        
        // Init state for myReview
        let book = BookInfo()
        book.editionId = editionId
        book.title = bookTitle
        
        // Set value for page field
        tfProcess.text = String(current)
        tfTotalPage.text = String(maxSlider)
        self.btnUpdateProgress.isHidden = self.maxSlider == 0
        
        // set on text change listener
        self.tfProcess.rx.controlEvent(.editingDidBegin).withLatestFrom(Observable.just(self))
            .map { (vc) -> String in
                if vc.tfProcess.text == "0" {
                    return ""
                }
                return vc.tfProcess.text ?? ""
        }.bind(to: self.tfProcess.rx.text).disposed(by: self.disposeBag)
        
        self.tfTotalPage.rx.controlEvent(.editingDidBegin).withLatestFrom(Observable.just(self))
            .map { (vc) -> String in
                if vc.tfTotalPage.text == "0" {
                    return ""
                }
                return vc.tfTotalPage.text ?? ""
        }.bind(to: self.tfTotalPage.rx.text).disposed(by: self.disposeBag)
        
        self.tfProcess.rx.controlEvent(.editingDidEnd).withLatestFrom(Observable.just(self.tfProcess).compactMap { $0 })
            .compactMap { (textField) -> String? in
                if textField.text == "" {
                    return "0"
                } else { return nil }
        }.bind(to: self.tfProcess.rx.text).disposed(by: self.disposeBag)
        
        self.tfTotalPage.rx.controlEvent(.editingDidEnd).withLatestFrom(Observable.just(self.tfTotalPage).compactMap { $0 })
            .compactMap { (textField) -> String? in
                if textField.text == "" {
                    return "0"
                } else { return nil }
        }.bind(to: self.tfTotalPage.rx.text).disposed(by: self.disposeBag)
        
        tfProcess.addTarget(self, action: #selector(tfProcessDidChange(_:)),
                            for: UIControl.Event.editingChanged)
        tfTotalPage.addTarget(self, action: #selector(tfTotalDidChange(_:)),
                              for: UIControl.Event.editingChanged)
        
        self.view.rx.tapGesture().when(.recognized).subscribe(onNext: { [weak self] (_) in
            self?.view.endEditing(true)
        }).disposed(by: self.disposeBag)
        
        var preferences = TipView.Preferences()
        preferences.drawing.font = .systemFont(ofSize: 12.0, weight: .regular)
        preferences.drawing.cornerRadius = 4.0
        preferences.drawing.backgroundColor = #colorLiteral(red: 0.4745098039, green: 0.7215686275, blue: 0.8509803922, alpha: 1)
        preferences.positioning.bubbleHInset = 0.0
        preferences.positioning.bubbleVInset = 0.0
        preferences.drawing.arrowPosition = .top
        let tipTotal = TipView(text: "TOTAL_PAGES".localized(), preferences: preferences, delegate: nil)
        self.tfTotalPage.rx.controlEvent(.editingDidBegin).withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.tfTotalPage.borderColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
                vc.tfTotalPage.borderWidth = 2.0
                tipTotal.show(animated: true, forView: vc.tfTotalPage, withinSuperview: vc.view)
            })
            .disposed(by: self.disposeBag)
        self.tfTotalPage.rx.controlEvent(.editingDidEnd).withLatestFrom(Observable.just(self)).subscribe(onNext: { (vc) in
            vc.tfTotalPage.borderColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
            vc.tfTotalPage.borderWidth = 1.0
            tipTotal.dismiss()
        })
            .disposed(by: self.disposeBag)
        
        let tipCurrent = TipView(text: "BOOK_YOU_HAVE_READ".localized(), preferences: preferences, delegate: nil)
        self.tfProcess.rx.controlEvent(.editingDidBegin).withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.tfProcess.borderColor = #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
                vc.tfProcess.borderWidth = 2.0
                tipCurrent.show(animated: true, forView: vc.tfProcess, withinSuperview: vc.view)
            })
            .disposed(by: self.disposeBag)
        self.tfProcess.rx.controlEvent(.editingDidEnd).withLatestFrom(Observable.just(self)).subscribe(onNext: { (vc) in
            vc.tfProcess.borderColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
            vc.tfProcess.borderWidth = 1.0
            tipCurrent.dismiss()
        })
            .disposed(by: self.disposeBag)
        
    }
    
    private func bindViewModel() {
        let useCase = Application.shared.networkUseCaseProvider
        viewModel = ReadingBookViewModel(
            readingUseCase: useCase.makeReadingUseCase(),
            reviewUseCase: useCase.makeReviewUseCase()
        )
        
        let input = ReadingBookViewModel.Input(
            editionId: self.editionId,
            addTrigger: addReading,
            updateTrigger: updateReading
        )
        
        let output = viewModel.transform(input)
        
        output.addResponse.subscribe(onNext: {
            print("Mapped Sequence: \($0)")
            ToastView.makeToast("MESSAGE_ADD_BOOK_TO_READINGS_SUCCESS".localized())
            SwiftEventBus.post(
                UpdateReadingEvent.EVENT_NAME,
                sender: nil
            )
            SwiftEventBus.post(
              RefreshChallengesEvent.EVENT_NAME,
              sender: nil
            )
            if self.readingStatus == 0 {
                self.performSegue(withIdentifier: ReviewProcessViewController.segueIdentifier, sender: nil)
            } else {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }).disposed(by: disposeBag)
        
        output.updateResponse.subscribe(onNext: {
            print("Mapped Sequence: \($0)")
            ToastView.makeToast("MESSAGE_UPDATE_PROGESS_SUCCESS".localized())
            SwiftEventBus.post(
                UpdateReadingEvent.EVENT_NAME,
                sender: nil
            )
            SwiftEventBus.post(
              RefreshChallengesEvent.EVENT_NAME,
              sender: nil
            )
            if self.readingStatus == 0 {
                self.performSegue(withIdentifier: ReviewProcessViewController.segueIdentifier, sender: nil)
            } else {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }).disposed(by: disposeBag)
        
        output.error
        .drive(rx.error)
        .disposed(by: disposeBag)
        
        output.indicator
        .drive(rx.isLoading)
        .disposed(by: disposeBag)
    }
    
    private var addReadingBinding: Binder<UpdateReadingResponse> {
        return Binder(self, binding: { (vc, response) in
            
        })
    }
    
    private var updateReadingBinding: Binder<UpdateReadingResponse> {
        return Binder(self, binding: { (vc, response) in
            
        })
    }
    
    @objc func tfProcessDidChange(_ textField: UITextField) {
        current = Int(textField.text ?? "0") ?? 0
        if current >= maxSlider {
            maxSlider = current
            tfTotalPage.text = String(maxSlider)
        }
        self.btnUpdateProgress.isHidden = self.maxSlider == 0
    }
    
    @objc func tfTotalDidChange(_ textField: UITextField) {
        maxSlider = Int(textField.text ?? "0") ?? 0
        if maxSlider < current {
            current = maxSlider
            tfProcess.text = String(current)
        }
        self.btnUpdateProgress.isHidden = self.maxSlider == 0
        
    }
    @IBAction func updateProgressDidTapped(_ sender: Any) {
        if self.current == self.maxSlider {
            self.readingStatus = 0
        } else {
            self.readingStatus = 1
        }
        if let readingId = self.readingId {
            var post: UpdateReadingPost?
            post = UpdateReadingPost(
            editionId: nil,
            pageNum: self.maxSlider,
            readPage: self.current,
            readingId: readingId,
            readingStatusId: self.readingStatus,
            startDate: self.startDate,
            completeDate: self.completeDate)
            self.updateReading.onNext(post!)
        } else {
            self.startDate = TimeUtils.convertDateToStr(Date(), TimeUtils.TIME_FORMAT_UTC)
            var post: UpdateReadingPost?
            post = UpdateReadingPost(
            editionId: self.editionId,
            pageNum: self.maxSlider,
            readPage: self.current,
            readingId: nil,
            readingStatusId: self.readingStatus,
            startDate: self.startDate,
            completeDate: "")
            self.addReading.onNext(post!)
        }
    }
    
    @IBAction func doneProcessDidTapped(_ sender: UIButton) {
        //complete
        self.showAlertConfirm()
    }
    
    
    fileprivate func showAlertConfirm() {
        let alert = UIAlertController.init(title: nil, message: "FINISH_READING_MESSAGE".localized(), preferredStyle: .alert)
        let ok = UIAlertAction(title: "DONE_READING_ALERT".localized(), style: .default) { [weak self] (_) in
            self?.processDone()
        }
        
        let cancel = UIAlertAction(title: "NOT_YET_READING_ALERT".localized(), style: .cancel, handler: nil)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func processDone() {
        self.readingStatus = 0
        self.tfProcess.text = self.tfTotalPage.text
        if let readingId = self.readingId {
            var post: UpdateReadingPost?
            post = UpdateReadingPost(
            editionId: nil,
            pageNum: self.maxSlider,
            readPage: self.maxSlider,
            readingId: readingId,
            readingStatusId: self.readingStatus,
            startDate: self.startDate,
            completeDate: self.completeDate)
            self.updateReading.onNext(post!)
        } else {
            self.startDate = TimeUtils.convertDateToStr(Date(), TimeUtils.TIME_FORMAT_UTC)
            var post: UpdateReadingPost?
            post = UpdateReadingPost(
            editionId: self.editionId,
            pageNum: self.maxSlider,
            readPage: self.maxSlider,
            readingId: nil,
            readingStatusId: self.readingStatus,
            startDate: self.startDate,
            completeDate: "")
            self.addReading.onNext(post!)
        }
    }
    
    @IBAction func onCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ReviewProcessViewController.segueIdentifier {
            let vc = segue.destination as? ReviewProcessViewController
            let book = BookInfo()
            book.editionId = self.editionId
            book.title = self.bookTitle
            vc?.book.accept(book)
            vc?.delegate = self.delegate
        }
    }
}
