//
//  SettingArticleViewController.swift
//  gat
//
//  Created by jujien on 8/21/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MBProgressHUD

extension NSAttributedString.Key {
    static let hashtag = NSAttributedString.Key(rawValue: "hash_tag")
}

class SettingArticleViewController: UIViewController {
    
    class var segueIdentifier: String { "showSettingArticle"}
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var categoryTitleLabel: UILabel!
    @IBOutlet weak var categoryPlaceholderLabel: UILabel!
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var tagTitleLabel: UILabel!
    @IBOutlet weak var tagDescriptionLabel: UILabel!
    @IBOutlet weak var tagTextView: UITextView!
    @IBOutlet weak var tagHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var bookDescriptionLabel: UILabel!
    @IBOutlet weak var bookTextView: UITextView!
    @IBOutlet weak var bookHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var seperateView: UIView!
    @IBOutlet weak var imageLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var chevronDownImageView: UIImageView!
    
    fileprivate var tagPlaceholder: UILabel!
    fileprivate var bookPlaceholder: UILabel!
    fileprivate let bookTableView = AutoCompleteTableView()
    fileprivate let hashtagTableView = AutoCompleteTableView()
    fileprivate let defaultBookAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: UIColor.navy]
    fileprivate let highlightBookAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.navy]
    fileprivate let defaultHashtagAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: UIColor.fadedBlue]
        
    fileprivate let delimeterSet: Set<String> = [",", " "]
    fileprivate let disposeBag = DisposeBag()
    
    var presenter: SettingArticlePresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupPlaceholder()
        self.setupCategory()
        self.setupHashtag()
        self.setupBookTag()
        self.setupBookAutoComplete()
        self.localizedString()
        self.presenter.previews.map { $0.count }.bind(to: self.pageControl.rx.numberOfPages).disposed(by: self.disposeBag)
        self.setupCollectionView()
        self.presenter.loading.map { !$0 }.bind(to: self.view.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
        self.presenter.loading.bind { [weak self] value in
            guard let view = self?.view else { return }
            if value {
                let hud = MBProgressHUD.showAdded(to: view, animated: true)
                hud.offset.y = -30
            } else {
                MBProgressHUD.hide(for: view, animated: true)
            }
            
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func localizedString(){
        self.tagDescriptionLabel.text = "REMIND_TAG_TITLE".localized()
        self.tagTitleLabel.text = "CHOOSE_TAG_IN_POST_TITLE".localized()
        self.bookDescriptionLabel.text = "REMIND_TAG_BOOK_TITLE".localized()
        self.bookTitleLabel.text = "MENTION_BOOK_TITLE".localized()
        self.imageLabel.text = "DISPLAY_COVER_TITLE".localized()
        self.titleLabel.text = "ARTICLE_SETTING".localized()
        self.saveButton.setTitle("SAVE_TAG_TITLE_POST".localized(), for: .normal)
    }
    
    fileprivate func setupCategory() {
        self.presenter.post.map { !$0.isReview }.bind(to: self.categoryView.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
        self.presenter.post.map { $0.isReview }.bind(to: self.chevronDownImageView.rx.isHidden).disposed(by: self.disposeBag)
        self.presenter.post.map { (post) -> String in
            if let reviewCategory = post.reviewCategory {
                return reviewCategory.title
            } else if let category = post.categories.first {
                return category.title
            }
            return "CHOOSE_CATERGORY_TITLE".localized()
        }
        .bind(to: self.categoryPlaceholderLabel.rx.text).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupPlaceholder() {
        self.setupTagPlaceholder()
        self.setupBookPlaceholder()
        self.tagHeightConstraint.constant = ceil(self.tagTextView.font!.lineHeight) + self.tagTextView.textContainerInset.top + self.tagTextView.textContainerInset.bottom
        self.bookHeightConstraint.constant = ceil(self.bookTextView.font!.lineHeight) + self.bookTextView.textContainerInset.top + self.bookTextView.textContainerInset.bottom
    }
    
    fileprivate func setupTagPlaceholder() {
        self.tagPlaceholder = .init()
        self.tagPlaceholder.text = "ENTER_TAG_TITLE".localized()
        self.tagPlaceholder.textColor = .greyBlue
        self.tagPlaceholder.font = .systemFont(ofSize: 14.0)
        self.view.addSubview(self.tagPlaceholder)
        
        self.tagPlaceholder.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20.0)
            maker.top.equalTo(self.tagTextView.snp.top).offset(self.tagTextView.textContainerInset.top)
        }
        self.presenter.post.elementAt(0).map { !$0.hashtags.isEmpty }.bind(to: self.tagPlaceholder.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupBookPlaceholder() {
        self.bookPlaceholder = .init()
        self.bookPlaceholder.text = "ENTER_BOOK_TITLE".localized()
        self.bookPlaceholder.textColor = .greyBlue
        self.bookPlaceholder.font = .systemFont(ofSize: 14.0)
        self.view.addSubview(self.bookPlaceholder)
        
        self.bookPlaceholder.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20.0)
            maker.top.equalTo(self.bookTextView.snp.top).offset(self.bookTextView.textContainerInset.top)
        }
        
        self.presenter.post.elementAt(0).map { !$0.editionTags.isEmpty }.bind(to: self.bookPlaceholder.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupHashtag() {
        self.tagTextView.delegate = self
        self.presenter.post.elementAt(0).withLatestFrom(Observable.just(self)) { (post, vc) -> NSAttributedString in
            guard !post.hashtags.isEmpty else { return .init(string: "", attributes: vc.defaultHashtagAttrs) }
            return .init(string: post.hashtags.map { $0.name }.joined(separator: "#"), attributes: vc.defaultHashtagAttrs)
        }
        .bind(to: self.tagTextView.rx.attributedText)
        .disposed(by: self.disposeBag)
        self.setupHashtagAutoComplete()
    }
    
    fileprivate func setupHashtagAutoComplete() {
        self.hashtagTableView.register(HashtagTableViewCell.self, forCellReuseIdentifier: HashtagTableViewCell.identifier)
        self.hashtagTableView.backgroundColor = .white
        self.hashtagTableView.rowHeight = 44.0
        self.hashtagTableView.frame = .init(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: 0.0)
        self.hashtagTableView.isHidden = true
        self.view.addSubview(self.hashtagTableView)
        
        self.presenter.autoCompleteHashtags
            .do(onNext: { [weak self] results in
                guard let vc = self else { return }
                var frame = vc.hashtagTableView.frame
                var height = vc.hashtagTableView.rowHeight * CGFloat(results.count)
                height = vc.tagTextView.frame.origin.y < height ? vc.tagTextView.frame.origin.y : height
                frame.size.height = height
                frame.origin.y = vc.tagTextView.frame.origin.y - height
                vc.hashtagTableView.isHidden = results.isEmpty
                vc.hashtagTableView.frame = frame
        })
        .bind(to: self.hashtagTableView.rx.items(cellIdentifier: HashtagTableViewCell.identifier, cellType: HashtagTableViewCell.self)) { [weak self]  (index, hashtag, cell) in
            guard let text = self?.presenter.currentHashtagSession?.filter else { return }
            let attrs = NSMutableAttributedString(string: "#\(hashtag.name)", attributes: [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: UIColor.fadedBlue])
            attrs.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: ("#\(hashtag.name)" as NSString).range(of: text))
            cell.textLabel?.attributedText = attrs
            cell.backgroundColor = .white
            cell.selectionStyle = .none
        }
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupBookTag() {
        self.bookTextView.delegate = self
        self.presenter.post.map { !$0.isReview }.bind(to: self.bookTextView.rx.isUserInteractionEnabled).disposed(by: self.disposeBag)
        self.presenter.post.elementAt(0).withLatestFrom(Observable.just(self)) { (post, vc) -> NSAttributedString in
            guard !post.editionTags.isEmpty else { return .init(string: "", attributes: vc.defaultBookAttrs) }
            return post.editionTags
                .map { (book) -> NSAttributedString in
                var attrs = vc.highlightBookAttrs
                attrs[.autocompleted] = true
                attrs[.autocompletedContext] = ["id": book.editionId]
                return .init(string: book.title, attributes: attrs)
            }
            .reduce(NSMutableAttributedString()) { (result, attr) -> NSMutableAttributedString in
                result.append(attr)
                if !post.isReview {
                    result.append(.init(string: vc.delimeterSet.map { $0 }.joined(), attributes: vc.defaultBookAttrs))
                }
                return result
            }
        }
        .bind(to: self.bookTextView.rx.attributedText)
        .disposed(by: self.disposeBag)
    }
    
    func autocomplete(hashtag: Hashtag) {
        guard var session = self.presenter.currentHashtagSession else { return }
        session.completion = .init(text: hashtag.name, context: nil)
        let insertionRange = NSRange(location: session.range.location, length: session.filter.utf16.count)
        guard let range = Range(insertionRange, in: self.tagTextView.text) else { return }
        let nsrange = NSRange(range, in: self.tagTextView.text)
        let autocomplete = session.completion?.text ?? ""
        self.insertHashtagAutocomplete(autocomplete, at: session, for: nsrange)
        let selectedLocation = session.range.location + autocomplete.utf16.count
        self.tagTextView.selectedRange = NSRange(location: selectedLocation, length: 0)
    }
    
    fileprivate func insertHashtagAutocomplete(_ autocomplete: String, at session: AutoCompletionSession, for range: NSRange) {
        let newAttributedString = NSAttributedString(string: autocomplete, attributes: [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: UIColor.fadedBlue])
        let highlightedRange = NSRange(location: range.location, length: range.length)
        let newAttributedText = self.tagTextView.attributedText.replacingCharacters(in: highlightedRange, with: newAttributedString)
        self.tagTextView.attributedText = NSAttributedString()
        self.tagTextView.attributedText = newAttributedText
    }
    
    fileprivate func setupBookAutoComplete() {
        self.bookTableView.register(.init(nibName: BookAutoCompleteTableViewCell.className, bundle: nil), forCellReuseIdentifier: BookAutoCompleteTableViewCell.identifier)
        self.bookTableView.separatorStyle = .none
        self.bookTableView.backgroundColor = .white
        self.bookTableView.rowHeight = 80.0
        self.bookTableView.frame = .init(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: 0.0)
        self.bookTableView.isHidden = true
        self.view.addSubview(self.bookTableView)
    
        self.presenter.autoCompleteBooks
            .do(onNext: { [weak self] (results) in
                guard let vc = self else { return }
                var frame = vc.bookTableView.frame
                var height = vc.bookTableView.rowHeight * CGFloat(results.count)
                height = vc.bookTextView.frame.origin.y < height ? vc.bookTextView.frame.origin.y : height
                frame.size.height = height
                frame.origin.y = vc.bookTextView.frame.origin.y - height
                vc.bookTableView.isHidden = results.isEmpty
                vc.bookTableView.frame = frame
            })
            .bind(to: self.bookTableView.rx.items(cellIdentifier: BookAutoCompleteTableViewCell.identifier, cellType: BookAutoCompleteTableViewCell.self)) { [weak self] (index, book, cell) in
                cell.book.accept(book)
                guard let text = self?.presenter.currentBookSession?.filter else { return }
                let matchingRange = (book.info!.title as NSString).range(of: text, options: .caseInsensitive)
                let attributes = NSMutableAttributedString(string: book.info!.title, attributes: [.font: UIFont.systemFont(ofSize: 15.0, weight: .regular), .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)])
                attributes.addAttributes([.font: UIFont.boldSystemFont(ofSize: 15.0)], range: matchingRange)
                cell.titleLabel.attributedText = attributes
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func autocompleteBook(title: String, context: [String: Any]) {
        guard var session = self.presenter.currentBookSession else { return }
        session.completion = .init(text: title, context: context)
        let insertionRange = NSRange(location: session.range.location, length: session.filter.utf16.count)
        guard let range = Range(insertionRange, in: self.bookTextView.text) else { return }
        let nsrange = NSRange(range, in: self.bookTextView.text)
        let autocomplete = session.completion?.text ?? ""
        self.insertBookAutocomplete(autocomplete, at: session, for: nsrange)
        let selectedLocation = insertionRange.location + autocomplete.utf16.count + self.delimeterSet.count // add delimeter
        self.bookTextView.selectedRange = NSRange(location: selectedLocation, length: 0)
    }
    
    fileprivate func insertBookAutocomplete(_ autocomplete: String, at session: AutoCompletionSession, for range: NSRange) {
        var attrs: [NSAttributedString.Key: Any] = self.highlightBookAttrs
        attrs[.autocompleted] = true
        attrs[.autocompletedContext] = session.completion?.context
        let newString = autocomplete
        let newAttributedString = NSAttributedString(string: newString, attributes: attrs)
        let highlightedRange = NSRange(location: range.location, length: range.length)
        let newAttributedText = self.bookTextView.attributedText.replacingCharacters(in: highlightedRange, with: newAttributedString)
        newAttributedText.append(.init(string: self.delimeterSet.map { $0 }.joined(), attributes: self.defaultBookAttrs))
        self.bookTextView.attributedText = NSAttributedString()
        self.bookTextView.attributedText = newAttributedText
    }
    
    fileprivate func setupCollectionView() {
        self.view.layoutIfNeeded()
        let max = UIScreen.main.bounds.height - self.collectionView.frame.origin.y - 16.0
        self.collectionHeightConstraint.constant = max > 272.0 ? 272.0 : max 
        self.collectionView.delegate = self
        self.collectionView.register(PreviewPostItemCollectionViewCell.self, forCellWithReuseIdentifier: PreviewPostItemCollectionViewCell.identifier)
        self.presenter.previews.bind(to: self.collectionView.rx.items(cellIdentifier: PreviewPostItemCollectionViewCell.identifier, cellType: PreviewPostItemCollectionViewCell.self)) { [weak self] (index, item, cell) in
            cell.item.accept(item)
            if let collectionView = self?.collectionView {
                cell.sizeCell = self?.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(row: index, section: 0)) ?? .zero
            }
            cell.imageHandler = self?.presenter.openImagePicker
        }
        .disposed(by: self.disposeBag)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.backEvent()
        self.saveEvent()
        self.tableViewEvent()
        self.hideKeyboardEvent()
        self.collectionViewEvent()
        self.selectCategoryEvent()
        self.hideMenu()
    }
    
    fileprivate func hideMenu() {
        NotificationCenter.default.rx.notification(UIMenuController.willShowMenuNotification)
            .subscribe(onNext: { (_) in
                let menu = UIMenuController.shared
                menu.setMenuVisible(true, animated: false)
                menu.perform(#selector(UIMenuController.setMenuVisible(_:animated:)), with: NSNumber(booleanLiteral: false))
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func backEvent() {
        self.backButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.presenter.backScreen()
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func saveEvent() {
        self.saveButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.presenter.save(hashtagText: vc.tagTextView.text)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func selectCategoryEvent() {
        self.categoryView.rx.tapGesture()
            .when(.recognized)
            .withLatestFrom(self.presenter.post)
            .filter { !$0.isReview }
            .subscribe(onNext: { [weak self] (post) in
                self?.presenter.openSelectCategory()
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func tableViewEvent() {
        self.bookTableView.rx.modelSelected(BookSharing.self).subscribe(onNext: { [weak self] (book) in
            self?.autocompleteBook(title: book.info!.title, context: ["id": book.id])
            self?.presenter.addTagBook(book.info!)
        }).disposed(by: self.disposeBag)
        
        self.hashtagTableView.rx.modelSelected(Hashtag.self).subscribe { [weak self] (hashtag) in
            self?.autocomplete(hashtag: hashtag)
            self?.presenter?.removeSessionHashtag()
        } onError: { (_) in
            
        } onCompleted: {
            
        } onDisposed: {
            
        }
        .disposed(by: self.disposeBag)

    }
    
    fileprivate func hideKeyboardEvent() {
        self.view.rx.tapGesture(configuration: { [weak self] (gesture, delegate) in
            delegate.touchReceptionPolicy = .custom({ [weak self] (gesture, touch) -> Bool in
                guard let bookTableView = self?.bookTableView, let tagTableView = self?.hashtagTableView, let isDescendantBook = touch.view?.isDescendant(of: bookTableView), let isDescendantTag = touch.view?.isDescendant(of: tagTableView) else { return false }
                return !isDescendantBook && !isDescendantTag
            })
        }).when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.presenter.sessionBookAutoComplete(nil)
                self?.presenter?.removeSessionHashtag()
                self?.view.endEditing(true)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.didScroll.withLatestFrom(Observable.just(self.collectionView)).compactMap { $0 }
            .map { (collectionView) -> Int in
                var index:Int
                index = Int(abs(collectionView.contentOffset.x) / collectionView.frame.width)
                return index
        }
        .bind(to: self.pageControl.rx.currentPage)
        .disposed(by: disposeBag)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
}

extension SettingArticleViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView === self.tagTextView {
            if textView.text.isEmpty {
                return text == "#"
            } else {
                if range.length == 0 { // check insert
                    if textView.text.last == "#" {
                        self.presenter.removeSessionHashtag()
                        return text != " " && (text.range(of: "[a-zA-Z0-9_\\p{Arabic}\\p{N}]", options: .regularExpression) != nil || text == "_")
                    } else {
                        return (text != " " && (text.range(of: "[a-zA-Z0-9_\\p{Arabic}\\p{N}]", options: .regularExpression) != nil || text == "_")) || text == "#"
                    }
                } else {
                    //check remove
                    if let cursorRange = Range(range, in: textView.text), textView.text[cursorRange] == "#" {
                        self.presenter.removeSessionHashtag()

                        let afterHashtagStr = String(textView.text[textView.text.index(from: range.location)..<textView.text.endIndex])
                        if let hashTagRemove = afterHashtagStr.split(separator: "#").map({ String($0) }).first {
                            let subrange = NSRange(location: range.location + 1, length: hashTagRemove.count)
                            let nothing = NSAttributedString(string: "", attributes: self.defaultHashtagAttrs)

                            // remove all text
                            textView.attributedText = textView.attributedText.replacingCharacters(in: subrange, with: nothing)
                            textView.selectedRange = NSRange(location: subrange.location, length: 0)
                        }
                        
                        
                        
                    }
                    return true
                }
            }
        } else if textView === self.bookTextView {
            self.bookTextView.typingAttributes = self.defaultBookAttrs
            let totalRange = NSRange(location: 0, length: textView.attributedText.length)
            let selectedRange = textView.selectedRange
            
            // range.length > 0: Backspace/removing text
            // range.lowerBound < textView.selectedRange.lowerBound: Ignore trying to delete
            //      the substring if the user is already doing so
            // range == selectedRange: User selected a chunk to delete
            if range.length > 0, range.location < selectedRange.location {
                // Backspace/removing text
                let attributes = textView.attributedText.attributes(at: range.location, longestEffectiveRange: nil, in: range)
                let isAutocompleted = attributes[.autocompleted] as? Bool ?? false
                
                if isAutocompleted {
                    textView.attributedText.enumerateAttribute(.autocompleted, in: totalRange, options: .reverse) { _, subrange, stop in
                        
                        let intersection = NSIntersectionRange(range, subrange)
                        guard intersection.length > 0 else { return }
                        defer { stop.pointee = true }
                        let nothing = NSAttributedString(string: "", attributes: self.defaultBookAttrs)
                        
                        if let context = textView.attributedText.attribute(.autocompletedContext, at: subrange.location, longestEffectiveRange: nil, in: subrange) as? [String: Any], let editionId = context["id"] as? Int {
                            self.presenter.removeTagBook(id: editionId)
                        }
                        // remove all text
                        textView.attributedText = textView.attributedText.replacingCharacters(in: subrange, with: nothing)
                        textView.selectedRange = NSRange(location: subrange.location, length: 0)
                    }
                    return false
                }
            } else if range.length >= 0, range.location < totalRange.length {
                // Inserting text before a tag when the tag is at the start of the string
                guard range.location != 0 else { return true }

                // Inserting text in the middle of an autocompleted string
                let attributes = textView.attributedText.attributes(at: range.location-1, longestEffectiveRange: nil, in: NSMakeRange(range.location-1, range.length))

                let isAutocompleted = attributes[.autocompleted] as? Bool ?? false
                if isAutocompleted {
                    textView.attributedText.enumerateAttribute(.autocompleted, in: totalRange, options: .reverse) { _, subrange, stop in
                        
                        let compareRange = range.length == 0 ? NSRange(location: range.location, length: 1) : range
                        let intersection = NSIntersectionRange(compareRange, subrange)
                        guard intersection.length > 0 else { return }
                        
                        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
                        mutable.setAttributes(self.defaultBookAttrs, range: subrange)
                        let replacementText = NSAttributedString(string: text, attributes: self.defaultBookAttrs)
                        textView.attributedText = mutable.replacingCharacters(in: range, with: replacementText)
                        textView.selectedRange = NSRange(location: range.location + text.count, length: 0)
                        stop.pointee = true
                    }
                    return false
                }
            }
            return true
        }
        return false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        switch textView {
        case self.tagTextView:
            self.tagPlaceholder.isHidden = !textView.text.isEmpty
            let height = self.tagTextView.sizeThatFits(.init(width: self.tagTextView.frame.width, height: .infinity)).height
            self.tagHeightConstraint.constant = height > 199.0 / 3.0 ? 199.0 / 3.0 : height
            if textView.selectedRange.location != 0 && textView.text.last != "#" {
                let beforeCursorText = String(textView.text[textView.text.startIndex..<textView.text.index(from: textView.selectedRange.location)])
                var afterCursorText = ""
                if textView.selectedRange.location < textView.text.count - 1 {
                    afterCursorText = String(textView.text[textView.text.index(from: textView.selectedRange.location)..<textView.text.endIndex])
                }
                let firstHashtag = beforeCursorText.split(separator: "#").map { String($0) }.last ?? ""
                var hashtag = firstHashtag
                if !afterCursorText.isEmpty && afterCursorText.first != "#" {
                    hashtag += afterCursorText.split(separator: "#").first ?? ""
                }
                if !hashtag.isEmpty {
                    let location = textView.selectedRange.location - firstHashtag.count
                    let range = NSRange(location: location, length: hashtag.count)
                    self.presenter.sessionHashtagAutoComplete(.init(prefix: "#", range: range, filter: hashtag))
                }
            }
        case self.bookTextView:
            let height = self.bookTextView.sizeThatFits(.init(width: self.bookTextView.frame.width, height: .infinity)).height
            self.bookHeightConstraint.constant = height > 199.0 / 3.0 ? 199.0 / 3.0 : height
            self.bookPlaceholder.isHidden = !textView.text.isEmpty
            if let result = self.bookTextView.find(with: self.delimeterSet.reduce(CharacterSet(), { $0.union(CharacterSet(charactersIn: $1)) })) {
                self.presenter.sessionBookAutoComplete(.init(prefix: result.prefix, range: result.range, filter: result.word))
            } else {
                self.presenter.sessionBookAutoComplete(nil)
            }
        default: break
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.tagTextView === textView, textView.text.isEmpty {
            textView.text = "#"
            self.tagPlaceholder.isHidden = !textView.text.isEmpty
        }
    }
}

extension SettingArticleViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch self.presenter.type(index: indexPath.row) {
        case .small: return .init(width: UIScreen.main.bounds.width, height: 194.0)
        case .medium: return .init(width: UIScreen.main.bounds.width, height: self.collectionHeightConstraint.constant)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}

extension SettingArticleViewController: UINavigationControllerDelegate { }

extension SettingArticleViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard var image = info[.originalImage] as? UIImage else { return }
        if image.imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        self.presenter.selectImage(image)
    }
}
