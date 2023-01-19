//
//  AddHashtahCategoryPostViewController.swift
//  gat
//
//  Created by jujien on 9/7/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import RxSwift

class AddHashtahCategoryPostViewController: BottomPopupViewController {
    
    class var identifier: String { Self.className }

    @IBOutlet weak var tagTitleLabel: UILabel!
    @IBOutlet weak var tagDescriptionLabel: UILabel!
    @IBOutlet weak var tagTextView: UITextView!
    @IBOutlet weak var tagHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var categoryTitleLabel: UILabel!
    @IBOutlet weak var seperateView: UIView!
    
    fileprivate var tagPlaceholder: UILabel!
    fileprivate let hashtagTableView = AutoCompleteTableView()
    
    fileprivate let defaultHashtagAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: UIColor.fadedBlue]
    
    override var popupHeight: CGFloat { return UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.height }
    
    override var popupTopCornerRadius: CGFloat { return 20.0 }
    
    override var popupPresentDuration: Double { return  0.3 }
    
    override var popupDismissDuration: Double { return 0.3 }
    
    override var popupShouldDismissInteractivelty: Bool { return true }
    
    override var popupDimmingViewAlpha: CGFloat { return BottomPopupConstants.kDimmingViewDefaultAlphaValue }
    

    var presenter: AddHashtagCategoryPostPresenter!
    
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.categoryTitleLabel.text = "REMIND_SELECT_ARTICLES_TYPE_TITLE".localized()
        self.tagTitleLabel.text = "CHOOSE_TAG_IN_POST_TITLE".localized()
        self.tagDescriptionLabel.text = "REMIND_TAG_TITLE".localized()
        self.saveButton.setTitle("SAVE_TAG_TITLE_POST".localized(), for: .normal)
        self.cancelButton.setTitle("CLOSE_TAG_POPUP_TITLE".localized(), for: .normal)
        
        self.searchTextField.attributedPlaceholder = .init(string: Gat.Text.SEARCH_PLACEHOLDER.localized(), attributes: [.foregroundColor: #colorLiteral(red: 0.2392156863, green: 0.2392156863, blue: 0.2588235294, alpha: 0.3), .font: UIFont.systemFont(ofSize: 14.0)])
        self.cancelButton.cornerRadius(radius: 9.0)
        self.saveButton.cornerRadius(radius: 9.0)
        self.cancelButton.layer.borderColor = UIColor.fadedBlue.cgColor
        self.cancelButton.layer.borderWidth = 1.0
        self.searchContainerView.cornerRadius(radius: 4.0)
        self.presenter.post.map { $0.isReview }.bind(to: self.searchContainerView.rx.isHidden, self.collectionView.rx.isHidden, self.categoryTitleLabel.rx.isHidden).disposed(by: self.disposeBag)
        self.setupHashtag()
        self.setupCollectionView()
    }
    
    fileprivate func setupHashtag() {
        self.tagTextView.delegate = self
        self.setupTagPlaceholder()
        self.tagHeightConstraint.constant = ceil(self.tagTextView.font!.lineHeight) + self.tagTextView.textContainerInset.top + self.tagTextView.textContainerInset.bottom
        self.tagTextView.delegate = self
        self.presenter.post.elementAt(0).withLatestFrom(Observable.just(self)) { (post, vc) -> NSAttributedString in
            guard !post.hashtags.isEmpty else { return .init(string: "", attributes: vc.defaultHashtagAttrs) }
            return .init(string: "#\(post.hashtags.map { $0.name }.joined(separator: "#"))", attributes: vc.defaultHashtagAttrs)
        }
        .bind(to: self.tagTextView.rx.attributedText)
        .disposed(by: self.disposeBag)
        self.setupHashtagAutoComplete()
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
                frame.size.height = vc.hashtagTableView.rowHeight * CGFloat(results.count)
                frame.origin = .init(x: 0.0, y: vc.seperateView.frame.origin.y)
                vc.hashtagTableView.isHidden = results.isEmpty
                vc.hashtagTableView.frame = frame
        })
        .bind(to: self.hashtagTableView.rx.items(cellIdentifier: HashtagTableViewCell.identifier, cellType: HashtagTableViewCell.self)) { [weak self]  (index, hashtag, cell) in
            guard let text = self?.presenter.currentHashtagSession?.filter else { return }
            let attrs = NSMutableAttributedString(string: "#\(hashtag.name)", attributes: self?.defaultHashtagAttrs ?? [:])
            attrs.addAttributes([.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold)], range: ("#\(hashtag.name)" as NSString).range(of: text))
            cell.textLabel?.attributedText = attrs
            cell.backgroundColor = .white
            cell.selectionStyle = .none
        }
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
    
    fileprivate func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.register(PostCategoryCollectionViewCell.self, forCellWithReuseIdentifier: PostCategoryCollectionViewCell.identifier)
        self.presenter.categories.bind(to: self.collectionView.rx.items(cellIdentifier: PostCategoryCollectionViewCell.identifier, cellType: PostCategoryCollectionViewCell.self)) { [weak self] (index, item, cell) in
            cell.item.accept(item)
            cell.itemSelected.accept(self?.presenter.selected.value?.categoryId == item.categoryId)
            if let collectionView = self?.collectionView {
                cell.sizeCell = self?.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: .init(row: index, section: 0)) ?? .zero
            }
        }.disposed(by: self.disposeBag)
    }

    // MARK: - Event
    fileprivate func event() {
        self.cancelEvent()
        self.saveEvent()
        self.collectionViewEvent()
        self.loadmoreEvent()
        self.searchEvent()
        self.tableViewEvent()
        self.view.rx.tapGesture(configuration: { [weak self] (gesture, delegate) in
            delegate.touchReceptionPolicy = .custom({ [weak self] (gesture, touch) -> Bool in
                guard let collectionView = self?.collectionView, let tableView = self?.hashtagTableView, let isDescendant = touch.view?.isDescendant(of: collectionView), let isDescendantTag = touch.view?.isDescendant(of: tableView) else { return false }
                return !isDescendant && !isDescendantTag
            })
        }).when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.presenter.removeSessionHashtag()
            self?.view.endEditing(true)
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func cancelEvent() {
        self.cancelButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.dismiss(animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func saveEvent() {
        self.saveButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.presenter.removeSessionHashtag()
                vc.presenter.update(hashtag: vc.tagTextView.text)
                vc.dismiss(animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func tableViewEvent() {
        self.hashtagTableView.rx.modelSelected(Hashtag.self).asObservable().bind { [weak self] (hashtag) in
            self?.autocomplete(hashtag: hashtag)
            self?.presenter.removeSessionHashtag()
        }
        .disposed(by: self.disposeBag)

    }
    
    fileprivate func collectionViewEvent() {
        self.collectionView.rx.modelSelected(PostCategory.self).subscribe(onNext: { [weak self] (item) in
            self?.presenter.selected.accept(item)
            self?.collectionView.reloadData()
        })
            .disposed(by: self.disposeBag)
        
        self.collectionView.rx.willBeginDecelerating.asObservable().compactMap { [weak self] _ in self?.collectionView }
            .filter({ (collectionView) -> Bool in
                return collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.frame.height)
            })
            .filter({ (collectionView) -> Bool in
                let translation = collectionView.panGestureRecognizer.translation(in: collectionView.superview)
                return translation.y < -70.0
            })
        .subscribe(onNext: { [weak self] (_) in
            // call api this here
            self?.presenter.next()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func loadmoreEvent() {
        self.collectionView.rx.willBeginDecelerating.asObservable().compactMap { [weak self] _ in self?.collectionView }
            .filter({ (collectionView) -> Bool in
                return collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.frame.height)
            })
            .filter({ (collectionView) -> Bool in
                let translation = collectionView.panGestureRecognizer.translation(in: collectionView.superview)
                return translation.y < -70.0
            })
        .subscribe(onNext: { [weak self] (_) in
            self?.presenter.next()
        }).disposed(by: self.disposeBag)
        
//        self.collectionView.rx.didScroll.asObservable().compactMap { [weak self] _ in self?.collectionView }
        
    }
    
    fileprivate func searchEvent() {
        self.searchTextField.rx.text.orEmpty.throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .bind(onNext: self.presenter.search(title:))
            .disposed(by: self.disposeBag)
    }
}

extension AddHashtahCategoryPostViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
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
    }
    
    func textViewDidChange(_ textView: UITextView) {
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
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "#"
            self.tagPlaceholder.isHidden = true 
        }
    }
}

extension AddHashtahCategoryPostViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width, height: 44.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}
