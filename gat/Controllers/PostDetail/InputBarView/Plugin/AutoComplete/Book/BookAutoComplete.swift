//
//  BookAutoComplete.swift
//  gat
//
//  Created by jujien on 5/12/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import InputBarAccessoryView

class BookAutoComplete: PrefixAutoComplete {
    
    fileprivate let results: BehaviorRelay<[BookSharing]> = .init(value: [])
    fileprivate let disposeBag = DisposeBag()
    fileprivate let text = BehaviorRelay<String>(value: "")
    fileprivate var visible: BehaviorRelay<Bool> = .init(value: false)
    fileprivate let tableView = AutoCompleteTableView()
    fileprivate let inputBar: CommentInputBar
    fileprivate let autoCompleteInput: AutoCompleteInput
    fileprivate var heightKeyboard: CGFloat = 0.0
    
    var prefix: String
    
    var attributedTextAttributes: [NSAttributedString.Key : Any]?
    
    var tags: Set<TagComment> = .init()
    
    init(prefix: String, attributedTextAttributes: [NSAttributedString.Key:Any]?, inputBar: CommentInputBar, autoCompleteInput: AutoCompleteInput) {
        self.prefix = prefix
        self.attributedTextAttributes = attributedTextAttributes
        self.inputBar = inputBar
        self.autoCompleteInput = autoCompleteInput
        self.getData()
        self.setupUI()
        self.event()
    }
}

extension BookAutoComplete {
    // MARK: - Data
    fileprivate func getData() {
        self.text.skip(1).do(onNext: { [weak self] (text) in
            self?.updateInputBar(height: .zero)
            guard text.isEmpty else { return }
            self?.visible.accept(!text.isEmpty)
        })
            .filter { !$0.isEmpty }
            .flatMap { SearchNetworkService.shared.book(title: $0, page: 1).catchErrorJustReturn(([], 0)) }.map { $0.0 }
            .do(onNext: { [weak self] (users) in
                guard users.isEmpty else { return }
                self?.setAutocompleteManager(active: false)
            })
            .subscribe(onNext: self.results.accept).disposed(by: self.disposeBag)

    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupTableView()
        self.visible.subscribe(onNext: self.setAutocompleteManager(active:)).disposed(by: self.disposeBag)
    }
    
    fileprivate func setAutocompleteManager(active: Bool) {
        let topStackView = self.inputBar.topStackView
        if active && !topStackView.arrangedSubviews.contains(self.tableView) {
            topStackView.insertArrangedSubview(self.tableView, at: topStackView.arrangedSubviews.count)
            topStackView.layoutIfNeeded()
        } else if !active && topStackView.arrangedSubviews.contains(self.tableView) {
            topStackView.removeArrangedSubview(self.tableView)
            topStackView.layoutIfNeeded()
            self.results.accept([])
            self.tableView.frame.size.height = .zero
        }
        self.inputBar.invalidateIntrinsicContentSize()
    }
    
    fileprivate func setupTableView() {
        self.tableView.register(.init(nibName: BookAutoCompleteTableViewCell.className, bundle: nil), forCellReuseIdentifier: BookAutoCompleteTableViewCell.identifier)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .white
        self.tableView.rowHeight = 104.0
        
        self.results
            .bind(to: self.tableView.rx.items(cellIdentifier: BookAutoCompleteTableViewCell.identifier, cellType: BookAutoCompleteTableViewCell.self)) { [weak self] (index, book, cell) in
                cell.book.accept(book)
                cell.titleLabel.attributedText = self?.autoCompleteInput.attributedText(matching: book.info!.title, fontSize: 14.0, keepPrefix: false)
        }.disposed(by: self.disposeBag)
        self.results.bind { [weak self] (results) in
            self?.updateInputBar(height: CGFloat(results.count) * (self?.tableView.rowHeight ?? .zero))
        }.disposed(by: self.disposeBag)
    }
    
     fileprivate func updateInputBar(height: CGFloat) {
         var height = height
         if height <= UIScreen.main.bounds.height * 0.9 - self.heightKeyboard {
             self.tableView.contentInset = .zero
         } else {
             height = UIScreen.main.bounds.height * 0.9 - self.heightKeyboard
             var contentInset = self.tableView.contentInset
            contentInset.bottom = self.inputBar.inputTextView.frame.height + 12.0
             self.tableView.contentInset = contentInset
         }
         self.tableView.frame = .init(origin: .zero, size: .init(width: self.tableView.frame.width, height: height))
         self.tableView.invalidateIntrinsicContentSize()
         self.tableView.superview?.layoutIfNeeded()
     }
    
    // MARK: - Event
    fileprivate func event() {
        self.tableView.rx.modelSelected(BookSharing.self).subscribe(onNext: { [weak self] (book) in
            let url = URL(string: AppConfig.sharedConfig.get("web_url") + "books/\(book.info!.editionId)")!
            self?.autoCompleteInput.set(completion: .init(text: book.info!.title, context: ["id": book.info!.editionId, "url": url, "prefix": self?.prefix ?? ""]))
            self?.tags.insert(.init(id: book.info!.editionId, text: book.info!.title))
            NotificationCenter.default.post(name: Self.ADD_BOOK_TAG, object: book.info!)
            self?.visible.accept(false)
        }).disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification).compactMap { (notification) -> CGFloat? in
            guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return nil }
            return value.cgRectValue.height
        }.subscribe(onNext: { [weak self] (value) in
            self?.heightKeyboard = value
        }).disposed(by: self.disposeBag)
    }
    
    func removeAllTags() {
        self.tags.removeAll()
    }
}

extension BookAutoComplete: AutoCompletionDelegate {
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, autocompleteSourceFor prefix: String, text: String) {
        guard self.prefix == prefix else { return }
        if text.isEmpty {
            self.visible.accept(false)
        }
        self.text.accept(text)
    }
    
    func autoCompleteImput(_ autoCompleteInput: AutoCompleteInput, prefix: String, shouldBecomeVisible: Bool) {
        self.visible.accept(shouldBecomeVisible)
    }
    
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, shouldInteractWith url: URL, prefix: String, context: [String: Any]) -> Bool {
        return false
    }
    
    func autoCompleteInput(_ autoCompleteInput: AutoCompleteInput, willDeleteCompletion context: [String : Any]) {
        guard let prefix = context["prefix"] as? String, let id = context["id"] as? Int, let tag = self.tags.first(where: { $0.id == id }), prefix == self.prefix else { return }
        self.tags.remove(tag)
        NotificationCenter.default.post(name: Self.REMOVE_BOOK_TAG, object: id)
    }
}

extension BookAutoComplete {
    static let ADD_BOOK_TAG = Notification.Name(rawValue: "add_book_tag_name")
    static let REMOVE_BOOK_TAG = Notification.Name("remove_book_tag_name")
}
