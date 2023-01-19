//
//  CreatePostViewController.swift
//  gat
//
//  Created by jujien on 8/18/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import UIKit
import WordPressEditor
import Aztec
import RxSwift
import RxCocoa
import MobileCoreServices
import Cosmos
import SwiftyGif

extension FormattingIdentifier {
    
    static let undo = FormattingIdentifier("undo")
    static let redo = FormattingIdentifier("redo")
    
    static let cancel = FormattingIdentifier("cancel")
    static let hideKeyboard = FormattingIdentifier("hide_keyboard")
}

class CreatePostViewController: UIViewController {
    
    class var segueIdentifier: String { "showCreatePost"}
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
    fileprivate var editorView: EditorView!
    fileprivate var toolbar: FormatBar!
    fileprivate var richTextView: TextView { self.editorView.richTextView }
    fileprivate var titleTextView: UITextView!
    fileprivate var titlePlaceholderLabel: UILabel!
    fileprivate var placeholderEditor: UILabel!
    fileprivate var separatorView: UIView!
    fileprivate let ratingTitleLabel = UILabel()
    fileprivate let ratingView = CosmosView()
    
    fileprivate var titleHeightConstraint: NSLayoutConstraint!
    fileprivate var titleTopConstraint: NSLayoutConstraint!
    fileprivate var titlePlaceholderTopConstraint: NSLayoutConstraint!
    fileprivate var titlePlaceholderLeadingConstraint: NSLayoutConstraint!
    
    fileprivate let DEFAULT_MARGIN_TITLE: CGFloat = 16.0
    fileprivate let STAR_SIZE: CGFloat = 20.0
    fileprivate let disposeBag = DisposeBag()
    
    var presenter: CreatePostPresenter!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.event()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.editorView.isScrollEnabled = true
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.settingButton.setTitle("SETTING_POST_TITLE".localized(), for: .normal)
        self.previewButton.setTitle("PREVIEW_POST_TITLE".localized(), for: .normal)
        self.edgesForExtendedLayout = UIRectEdge()
        self.createToolbar()
        self.setupEditorView()
        self.setupTitleTextView()
        self.setupTitlePlaceholder()
        self.setupSeparatorView()
        self.setupPlaceholderEditor()
        self.setupRatingView()
        self.configureConstraints()
        self.view.bringSubviewToFront(self.headerView)
        self.presenter.post.map { $0.body }.elementAt(0).bind(to: self.editorView.rx.html).disposed(by: self.disposeBag)
        self.presenter.getBodyIfNeeded.bind(to: self.editorView.rx.html).disposed(by: self.disposeBag)
    }
    
    fileprivate func createToolbar() {
        self.toolbar = Aztec.FormatBar()
        self.toolbar.frame = CGRect(x: .zero, y: .zero, width: self.view.frame.width, height: 44.0)
        self.toolbar.autoresizingMask = [.flexibleHeight]
        self.toolbar.formatter = self
        self.setDefaultItems()
        self.toolbar.backgroundColor = .white
        self.toolbar.dividerTintColor = .paleBlue
    }

    fileprivate func setDefaultItems() {
        let header = FormatBarItem(image: #imageLiteral(resourceName: "Tt"), identifier: FormattingIdentifier.header2.rawValue)
        header.alternativeIcons = [FormattingIdentifier.header2.rawValue: #imageLiteral(resourceName: "tbighighlight"), FormattingIdentifier.header4.rawValue: #imageLiteral(resourceName: "tsmallhighlight")]
        let list = FormatBarItem(image: #imageLiteral(resourceName: "undorlist"), identifier: FormattingIdentifier.unorderedlist.rawValue)
        list.alternativeIcons = [FormattingIdentifier.unorderedlist.rawValue: #imageLiteral(resourceName: "undorlisthighlight")]
        let blockquote = FormatBarItem(image: #imageLiteral(resourceName:"blockquote"), identifier: FormattingIdentifier.blockquote.rawValue)
        blockquote.alternativeIcons = [FormattingIdentifier.blockquote.rawValue: #imageLiteral(resourceName: "blockquotehighlight")]
        self.toolbar.setDefaultItems([
            header,
            blockquote,
            .init(image: #imageLiteral(resourceName: "media"), identifier: FormattingIdentifier.media.rawValue),
            list,
        ])
        let more = FormatBarItem(image: #imageLiteral(resourceName: "moreformat"), identifier: FormattingIdentifier.more.rawValue)
        self.toolbar.leadingItem = more
        self.toolbar.trailingItem = FormatBarItem.init(image: #imageLiteral(resourceName: "hidekeyboard"), identifier: FormattingIdentifier.hideKeyboard.rawValue)
    }
    
    fileprivate func setMoreItems() {
        let undo = FormatBarItem(image: #imageLiteral(resourceName: "undo"), identifier: FormattingIdentifier.undo.rawValue)
        let redo = FormatBarItem(image: #imageLiteral(resourceName: "redo"), identifier: FormattingIdentifier.redo.rawValue)
        let horizontalruler = FormatBarItem(image: #imageLiteral(resourceName: "br"), identifier: FormattingIdentifier.horizontalruler.rawValue)
        let link = FormatBarItem(image: #imageLiteral(resourceName: "url"), identifier: FormattingIdentifier.link.rawValue)
        self.toolbar.setDefaultItems([
            undo,
            redo,
            horizontalruler,
            link,
        ])
        self.toolbar.leadingItem = FormatBarItem(image: #imageLiteral(resourceName: "cancelformat"), identifier: FormattingIdentifier.cancel.rawValue)
    }
    
    fileprivate func setupEditorView() {
        self.editorView = EditorView(defaultFont: .systemFont(ofSize: 16.0, weight: .regular), defaultHTMLFont: .systemFont(ofSize: 16.0, weight: .regular), defaultParagraphStyle: .default, defaultMissingImage: #imageLiteral(resourceName: "lazyImage"))
        self.editorView.clipsToBounds = true
        self.editorView.backgroundColor = .white
        
        let providers: [TextViewAttachmentImageProvider] = [
            GutenpackAttachmentRenderer(),
            SpecialTagAttachmentRenderer(),
            CommentAttachmentRenderer(font: .systemFont(ofSize: 16.0, weight: .regular)),
            HTMLAttachmentRenderer(font: .systemFont(ofSize: 16.0, weight: .regular)),
        ]
        providers.forEach(self.richTextView.registerAttachmentImageProvider(_:))
        self.setupRichTextView(self.richTextView)
        self.view.addSubview(self.editorView)
        self.editorView.isScrollEnabled = false
    }
    
    fileprivate func setupRichTextView(_ textView: TextView) {
        textView.delegate = self
        self.configureDefaultProperties(for: textView, font: .systemFont(ofSize: 16.0, weight: .regular))
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self
        textView.textColor = UIColor.navy.withAlphaComponent(0.67)
        textView.clipsToBounds = false
        textView.linkTextAttributes = [.font: UIFont.systemFont(ofSize: 16.0, weight: .bold), .foregroundColor: UIColor.fadedBlue]
        if #available(iOS 11.0, *) {
            textView.smartDashesType = .no
            textView.smartQuotesType = .no
        } else {  }
        textView.showsVerticalScrollIndicator = false
        textView.textContainer.lineFragmentPadding = 0
    }
    
    fileprivate func configureDefaultProperties(for textView: UITextView, font: UIFont) {
        textView.font = font
        textView.keyboardDismissMode = .interactive
        textView.textColor = UIColor.navy.withAlphaComponent(0.67)
        textView.backgroundColor = .white
    }
    
    fileprivate func setupTitleTextView() {
        self.titleTextView = UITextView()
        self.titleTextView.delegate = self
        self.titleTextView.font = .systemFont(ofSize: 22.0, weight: .bold)
        self.titleTextView.returnKeyType = .next
        self.titleTextView.textColor = .navy
        self.titleTextView.translatesAutoresizingMaskIntoConstraints = false
        self.titleTextView.backgroundColor = .clear
        self.titleTextView.textAlignment = .natural
        self.titleTextView.isScrollEnabled = false
        self.titleTextView.backgroundColor = .white
        self.view.addSubview(self.titleTextView)
        self.presenter.post.elementAt(0).map { $0.title }.bind(to: self.titleTextView.rx.text).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTitlePlaceholder() {
        self.titlePlaceholderLabel = .init()
        self.titlePlaceholderLabel.attributedText = .init(string: "ADD_TITLE_POST".localized(), attributes: [.font: UIFont.systemFont(ofSize: 22.0, weight: .semibold), .foregroundColor: UIColor.greyBlue])
        self.titlePlaceholderLabel.sizeToFit()
        self.titlePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.titlePlaceholderLabel)
        self.presenter.post.elementAt(0).map { !$0.title.isEmpty }.bind(to: self.titlePlaceholderLabel.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupPlaceholderEditor() {
        self.placeholderEditor = .init()
        self.presenter.post.map { (post) -> NSAttributedString in
            var text: String = "ADD_CONTENT_POST".localized()
            if let book = post.editionTags.first, post.isReview {
                text = String(format:"ENTER_BOOK_REVIEW_POST".localized(),book.title)
            }
            return .init(string: text, attributes: [.font: UIFont.systemFont(ofSize: 16.0, weight: .regular), .foregroundColor: UIColor.greyBlue])
        }
        .bind(to: self.placeholderEditor.rx.attributedText)
        .disposed(by: self.disposeBag)
        self.placeholderEditor.sizeToFit()
        self.placeholderEditor.translatesAutoresizingMaskIntoConstraints = false
        self.placeholderEditor.textAlignment = .natural
        self.placeholderEditor.numberOfLines = 0
        self.view.addSubview(self.placeholderEditor)
        self.presenter.post.elementAt(0).map { !$0.body.isEmpty }.bind(to: self.placeholderEditor.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupSeparatorView() {
        self.separatorView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 1))

        self.separatorView.backgroundColor = .brownGreyThree
        self.separatorView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.separatorView)
    }
    
    fileprivate func setupRatingView() {
        self.ratingTitleLabel.text = "RATE_TITLE_COMMENT".localized()
        self.ratingTitleLabel.font = .systemFont(ofSize: 14.0)
        self.ratingTitleLabel.textColor = .navy
        self.ratingTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.ratingTitleLabel)
        
        self.ratingView.settings.emptyBorderColor = .clear
        self.ratingView.settings.emptyColor = .paleBlue
        self.ratingView.settings.filledColor = .apricot
        self.ratingView.settings.filledBorderColor = .clear
        self.ratingView.settings.starMargin = 0.0
        self.ratingView.settings.starSize = Double(self.STAR_SIZE)
        self.ratingView.settings.totalStars = 5
        self.ratingView.backgroundColor = .white
        self.ratingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.ratingView)
        self.presenter.post.elementAt(0).map { $0.rating }.subscribe(onNext: { [weak self] (value) in
            self?.ratingView.rating = value
        })
            .disposed(by: self.disposeBag)
        self.presenter.post.elementAt(0).map { !$0.isReview }.bind(to: self.ratingView.rx.isHidden, self.ratingTitleLabel.rx.isHidden).disposed(by: self.disposeBag)
    }
    
    fileprivate func showLinkDialog(forURL url: URL?, text: String?, target: String?, range: NSRange, allowTextEdit: Bool = true) {
        
        let isInsertingNewLink = (url == nil)
        var urlToUse = url
        
        if isInsertingNewLink {
            let pasteboard = UIPasteboard.general
            if let pastedURL = pasteboard.value(forPasteboardType:String(kUTTypeURL)) as? URL {
                urlToUse = pastedURL
            }
        }
        
        let insertButtonTitle = isInsertingNewLink ? NSLocalizedString("INSERT_LINK_CREATE_POST".localized(), comment:"Label action for inserting a link on the editor") : NSLocalizedString("UPDATE_LINK_CREATE_POST".localized(), comment:"Label action for updating a link on the editor")
        let removeButtonTitle = NSLocalizedString("REMOVE_LINK_CREATE_POST".localized(), comment:"Label action for removing a link from the editor");
        let cancelButtonTitle = NSLocalizedString("CANCEL_ALERT_TITLE_HOME".localized(), comment:"Cancel button")
        
        let alertController = UIAlertController(title:insertButtonTitle,
                                                message:nil,
                                                preferredStyle:UIAlertController.Style.alert)
//        alertController.view.accessibilityIdentifier = "linkModal"
        
        alertController.addTextField(configurationHandler: { [weak self]textField in
            textField.clearButtonMode = UITextField.ViewMode.always;
            textField.placeholder = NSLocalizedString("URL", comment:"URL text field placeholder");
            textField.keyboardType = .URL
            textField.textContentType = .URL
            textField.text = urlToUse?.absoluteString
            
            textField.addTarget(self,
                                action:#selector(CreatePostViewController.alertTextFieldDidChange),
                                for:UIControl.Event.editingChanged)
            
//            textField.accessibilityIdentifier = "linkModalURL"
        })
        
        if allowTextEdit {
            alertController.addTextField(configurationHandler: { textField in
                textField.clearButtonMode = UITextField.ViewMode.always
                textField.placeholder = NSLocalizedString("LINK_TEXT_POST".localized(), comment:"Link text field placeholder")
                textField.isSecureTextEntry = false
                textField.autocapitalizationType = UITextAutocapitalizationType.sentences
                textField.autocorrectionType = UITextAutocorrectionType.default
                textField.spellCheckingType = UITextSpellCheckingType.default
                
                textField.text = text;
                
//                textField.accessibilityIdentifier = "linkModalText"
                
            })
        }
        
//        alertController.addTextField(configurationHandler: { textField in
//            textField.clearButtonMode = UITextField.ViewMode.always
//            textField.placeholder = NSLocalizedString("Target", comment:"Link text field placeholder")
//            textField.isSecureTextEntry = false
//            textField.autocapitalizationType = UITextAutocapitalizationType.sentences
//            textField.autocorrectionType = UITextAutocorrectionType.default
//            textField.spellCheckingType = UITextSpellCheckingType.default
//
//            textField.text = target;
//
////            textField.accessibilityIdentifier = "linkModalTarget"
//
//        })
        
        let insertAction = UIAlertAction(title:insertButtonTitle, style:UIAlertAction.Style.default, handler:{ [weak self] action in
            
            self?.richTextView.becomeFirstResponder()
            guard let textFields = alertController.textFields else {
                return
            }
            let linkURLField = textFields[0]
            let linkTextField = textFields[1]
//            let linkTargetField = textFields[2]
            let linkURLString = linkURLField.text
            var linkTitle = linkTextField.text
//            let target = linkTargetField.text
            
            if  linkTitle == nil  || linkTitle!.isEmpty {
                linkTitle = linkURLString
            }
            
            guard
                let urlString = linkURLString,
                let url = URL(string:urlString)
                else {
                    return
            }
            if allowTextEdit {
                if let title = linkTitle {
                    self?.richTextView.setLink(url, title: title, target: nil/*target*/, inRange: range)
                }
            } else {
                self?.richTextView.setLink(url, target: /*target*/nil, inRange: range)
            }
        })
        
//        insertAction.accessibilityLabel = "insertLinkButton"
        
        let removeAction = UIAlertAction(title:removeButtonTitle, style:UIAlertAction.Style.destructive, handler:{ [weak self] action in
            self?.richTextView.becomeFirstResponder()
            self?.richTextView.removeLink(inRange: range)
        })
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style:UIAlertAction.Style.cancel, handler:{ [weak self]action in
            self?.richTextView.becomeFirstResponder()
        })
        
        alertController.addAction(insertAction)
        if !isInsertingNewLink {
            alertController.addAction(removeAction)
        }
        alertController.addAction(cancelAction)
        
        // Disabled until url is entered into field
        if let text = alertController.textFields?.first?.text {
            insertAction.isEnabled = !text.isEmpty
        }
        
        self.present(alertController, animated:true, completion:nil)
    }
    @objc func alertTextFieldDidChange(_ textField: UITextField) {
        guard
            let alertController = presentedViewController as? UIAlertController,
            let urlFieldText = alertController.textFields?.first?.text,
            let insertAction = alertController.actions.first
            else {
                return
        }
        
        insertAction.isEnabled = !urlFieldText.isEmpty
    }
    
    // MARK: - Configuration Constraints
    override func updateViewConstraints() {
        self.updateTitlePosition()
        self.updateTitleHeight()
        super.updateViewConstraints()
    }
    
    private func configureConstraints() {
        self.titleHeightConstraint = self.titleTextView.heightAnchor.constraint(equalToConstant: ceil(self.titleTextView.font!.lineHeight))
        //        self.titleTopConstraint = self.titleTextView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.0)
        self.titleTopConstraint = self.titleTextView.topAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: self.DEFAULT_MARGIN_TITLE)
        self.titlePlaceholderTopConstraint = self.titlePlaceholderLabel.topAnchor.constraint(equalTo: self.titleTextView.topAnchor, constant: 0.0)
        self.titlePlaceholderLeadingConstraint = self.titlePlaceholderLabel.leadingAnchor.constraint(equalTo: self.titleTextView.leadingAnchor, constant: 0)
        self.updateTitlePosition()
        self.updateTitleHeight()
        
        let layoutGuide = self.view.readableContentGuide
        
        NSLayoutConstraint.activate([
            self.titleTextView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0),
            self.titleTextView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            self.titleHeightConstraint,
            self.titleTopConstraint
        ])
        
        NSLayoutConstraint.activate([
            self.titlePlaceholderLeadingConstraint,
            self.titlePlaceholderLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            titlePlaceholderTopConstraint
        ])
        
        NSLayoutConstraint.activate([
            self.separatorView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0),
            self.separatorView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            self.separatorView.topAnchor.constraint(equalTo: self.titleTextView.bottomAnchor, constant: self.DEFAULT_MARGIN_TITLE),
            self.separatorView.heightAnchor.constraint(equalToConstant: self.separatorView.frame.height)
        ])
        
        NSLayoutConstraint.activate([
            self.ratingTitleLabel.leadingAnchor.constraint(equalTo: self.separatorView.leadingAnchor, constant: 0.0),
            self.ratingTitleLabel.topAnchor.constraint(equalTo: self.separatorView.bottomAnchor, constant: 8.0)
        ])
        
        NSLayoutConstraint.activate([
            self.ratingView.leadingAnchor.constraint(equalTo: self.ratingTitleLabel.trailingAnchor, constant: 8.0),
            self.ratingView.centerYAnchor.constraint(equalTo: self.ratingTitleLabel.centerYAnchor, constant: 0.0),
            self.ratingView.heightAnchor.constraint(equalToConstant: self.STAR_SIZE)
        ])
        
        NSLayoutConstraint.activate([
            self.editorView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            self.editorView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            self.editorView.topAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: 0),
            self.editorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
            
        var spacing: CGFloat = 18.0
        if self.presenter.isReview {
            spacing += self.STAR_SIZE + 8.0
        }
        NSLayoutConstraint.activate([
            self.placeholderEditor.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0.0),
            self.placeholderEditor.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0.0),
            self.placeholderEditor.topAnchor.constraint(equalTo: self.separatorView.bottomAnchor, constant: self.richTextView.textContainerInset.top + spacing)
        ])
    }
    
    fileprivate func updateTitlePosition() {
        self.titleTopConstraint.constant = -(self.editorView.contentOffset.y + self.editorView.contentInset.top) + self.DEFAULT_MARGIN_TITLE
        self.titlePlaceholderTopConstraint.constant = self.titleTextView.textContainerInset.top + self.titleTextView.contentInset.top
        self.titlePlaceholderLeadingConstraint.constant = self.titleTextView.textContainerInset.left + self.titleTextView.contentInset.left  + self.titleTextView.textContainer.lineFragmentPadding
        
        //        var contentInset = self.editorView.contentInset
        //        contentInset.top = self.titleHeightConstraint.constant + self.separatorView.frame.height + self.titleTopConstraint.constant * 2.0
        //        self.editorView.contentInset = contentInset
        //
        //        self.updateScrollInsets()
    }
    
    fileprivate func updateTitleHeight() {
        let layoutMargins = view.layoutMargins
        let insets = self.titleTextView.textContainerInset

        var titleWidth = self.titleTextView.bounds.width
        if titleWidth <= 0 {
            // Use the title text field's width if available, otherwise calculate it.
            titleWidth = view.frame.width - (insets.left + insets.right + layoutMargins.left + layoutMargins.right)
        }

        let sizeThatShouldFitTheContent = self.titleTextView.sizeThatFits(CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude))
        self.titleHeightConstraint.constant = max(sizeThatShouldFitTheContent.height, self.titleTextView.font!.lineHeight + insets.top + insets.bottom)

        self.titlePlaceholderLabel.isHidden = !self.titleTextView.text.isEmpty
        
        var spacingRating: CGFloat = 0.0
        if self.presenter.isReview {
            spacingRating = self.STAR_SIZE + 8.0
        }

        var contentInset = self.editorView.contentInset
        contentInset.top = (self.titleHeightConstraint.constant + self.separatorView.frame.height) + spacingRating + 50.0
        self.editorView.contentInset = contentInset
        self.editorView.contentOffset = CGPoint(x: 0, y: -contentInset.top)
    }
    
    fileprivate func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        let localKeyboardOrigin = self.view.convert(keyboardFrame.origin, from: nil)
        let keyboardInset = max(self.view.frame.height - localKeyboardOrigin.y, 0)
        let contentInset = UIEdgeInsets(top: self.editorView.contentInset.top, left: .zero, bottom: keyboardInset, right: .zero)

        self.editorView.contentInset = contentInset
        self.updateScrollInsets()
    }
    
    fileprivate func updateScrollInsets() {
        var scrollInsets = self.editorView.contentInset
        var rightMargin = (self.view.frame.maxX - self.editorView.frame.maxX)
        if #available(iOS 11.0, *) {
            rightMargin -= self.view.safeAreaInsets.right
        } else {
        }
        scrollInsets.right = -rightMargin
        self.editorView.scrollIndicatorInsets = scrollInsets
    }

    fileprivate func changeRichTextInputView(to: UIView?) {
        if self.richTextView.inputView == to { return }
        self.richTextView.inputView = to
        self.richTextView.reloadInputViews()
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.keyboardEvent()
        self.backEvent()
        self.settingEvent()
        self.previewEvent()
        self.ratingEvent()
        self.toolbar.barItemHandler = self.itemToolbarHandler(item: )
        self.toolbar.leadingItemHandler = self.toolbarLeadingHandler
        self.toolbar.trailingItemHandler = self.toolbarTrailingHandler
//        self.hideMenu()
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
    
    fileprivate func keyboardEvent() {
        Observable.of(
            NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification),
            NotificationCenter.default.rx.notification(UIResponder.keyboardDidHideNotification)
        )
            .merge()
            .flatMap { (notification) -> Observable<CGRect> in
                guard let userInfo = notification.userInfo as? [String: AnyObject], let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                        return .empty()
                }
                return .just(keyboardFrame)
            }
        .subscribe(onNext: { [weak self] (rect) in
            self?.refreshInsets(forKeyboardFrame: rect)
        })
            .disposed(by: self.disposeBag)
    }

    fileprivate func backEvent() {
        self.backButton.rx.tap
            .withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
            vc.presenter.back(title: vc.titleTextView.text, body: vc.richTextView.getHTML(), text: vc.richTextView.text)
        }).disposed(by: self.disposeBag)
    }

    fileprivate func settingEvent() {
        self.settingButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.presenter.openSetting(title: vc.titleTextView.text, body: vc.editorView.getHTML(), text: vc.richTextView.text)
            })
        .disposed(by: self.disposeBag)
    }
    
    fileprivate func previewEvent() {
        self.previewButton.rx.tap.withLatestFrom(Observable.just(self))
            .subscribe(onNext: { (vc) in
                vc.editorView.resignFirstResponder()
                vc.presenter.openPreview(title: vc.titleTextView.text, body: vc.richTextView.getHTML(), text: vc.richTextView.text)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func itemToolbarHandler(item: FormatBarItem) {
        guard let identifier = item.identifier, let formattingIdentifier = FormattingIdentifier(rawValue: identifier) else { return }
        switch formattingIdentifier {
        case .header2:
            if item.imageView?.image == #imageLiteral(resourceName: "Tt") {
                self.richTextView.toggleHeader(.h2, range: self.richTextView.selectedRange)

            } else {
                self.richTextView.toggleHeader(.h4, range: self.richTextView.selectedRange)
            }
        case .header4: self.richTextView.toggleHeader(.h4, range: self.richTextView.selectedRange)
        case .blockquote:
            self.richTextView.toggleBlockquote(range: self.richTextView.selectedRange)
        case .unorderedlist: self.richTextView.toggleUnorderedList(range: self.richTextView.selectedRange)
        case .horizontalruler:
            self.richTextView.replaceWithHorizontalRuler(at: self.richTextView.selectedRange)
        case .media:
            self.view.endEditing(true)
            self.presenter.showImagePicker()
        case .undo: self.richTextView.undoManager?.undo()
        case .redo: self.richTextView.undoManager?.redo()
        case .link: self.toggleLink()
        default: break
        }
        self.updateFormatBar()
    }
    
    fileprivate func toolbarLeadingHandler(_ button: UIButton) {
        guard let item = button as? FormatBarItem, let identifier = item.identifier else { return }
        let formattingIdentifier = FormattingIdentifier(identifier)
        if formattingIdentifier == .more {
            self.setMoreItems()
        } else if formattingIdentifier == .cancel {
            self.setDefaultItems()
        }
    }
    
    fileprivate func toolbarTrailingHandler(_ button: UIButton) {
        self.view.endEditing(true)
    }
    
    fileprivate func updateFormatBar() {
        guard let toolbar = self.richTextView.inputAccessoryView as? Aztec.FormatBar else { return }
        let identifiers: Set<FormattingIdentifier>
        if self.richTextView.selectedRange.length > 0 {
            identifiers = self.richTextView.formattingIdentifiersSpanningRange(self.richTextView.selectedRange)
        } else {
            identifiers = self.richTextView.formattingIdentifiersForTypingAttributes()
        }

        toolbar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
        toolbar.items.forEach { (item) in
            guard let identifier = item.identifier, let formattingIdentifier = FormattingIdentifier(rawValue: identifier) else { return }
            switch formattingIdentifier {
            case .header2, .header4:
                if !identifiers.contains(formattingIdentifier) {
                    item.identifier = FormattingIdentifier.header2.rawValue
                    item.isSelected = false
                }
            case .unorderedlist:
                if !identifiers.contains(formattingIdentifier) {
                    item.identifier = FormattingIdentifier.unorderedlist.rawValue
                    item.isSelected = false
                }
            default: break
            }
        }
    }
    
    func toggleLink() {
        var linkTitle = ""
        var linkURL: URL? = nil
        var linkRange = self.richTextView.selectedRange
        // Let's check if the current range already has a link assigned to it.
        if let expandedRange = self.richTextView.linkFullRange(forRange: self.richTextView.selectedRange) {
           linkRange = expandedRange
           linkURL = self.richTextView.linkURL(forRange: expandedRange)
        }
        let target = self.richTextView.linkTarget(forRange: self.richTextView.selectedRange)
        linkTitle = self.richTextView.attributedText.attributedSubstring(from: linkRange).string
        let allowTextEdit = !self.richTextView.attributedText.containsAttachments(in: linkRange)
        self.showLinkDialog(forURL: linkURL, text: linkTitle, target: target, range: linkRange, allowTextEdit: allowTextEdit)
    }
    
    fileprivate func ratingEvent() {
        self.ratingView.didFinishTouchingCosmos = self.presenter.ratingHandler
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }


}

extension CreatePostViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        var enable = false
        switch textView {
        case self.richTextView:
            enable = true
            textView.textColor = UIColor.navy.withAlphaComponent(0.67)
        case self.titleTextView:
            enable = false
            textView.textColor = .navy
        default: break
        }
        self.toolbar.enabled = enable
        textView.inputAccessoryView = enable ? self.toolbar : nil
        return true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        self.updateFormatBar()
        self.changeRichTextInputView(to: nil)
    }

    func textViewDidChange(_ textView: UITextView) {
        switch textView {
        case self.richTextView:
            self.updateFormatBar()
            textView.textColor = UIColor.navy.withAlphaComponent(0.67)
            self.placeholderEditor.isHidden = !textView.text.isEmpty
        case self.titleTextView:
            self.updateTitleHeight()
            textView.textColor = .navy
        default: break
        }
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print(URL)
        return true 
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateTitlePosition()
    }
}

extension CreatePostViewController: FormatBarDelegate {
    func formatBarTouchesBegan(_ formatBar: FormatBar) {}
     
    func formatBar(_ formatBar: FormatBar, didChangeOverflowState overflowState: FormatBarOverflowState) { }
}

extension CreatePostViewController: TextViewFormattingDelegate {
    func textViewCommandToggledAStyle() {
        self.updateFormatBar()
    }
}

extension CreatePostViewController: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        self.presenter.download(url: url).catchError { (error) -> Observable<UIImage> in
            failure()
            return .empty()
        }
        .subscribe(onNext: success)
        .disposed(by: self.disposeBag)
    }
    
    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return nil
    }
    
    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage { #imageLiteral(resourceName: "lazyImage") }
    
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
        if let attachment = attachment as? ImageAttachment, let url = attachment.url {
            self.presenter.removeImage(url: url)
        }
    }
    
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        guard let mediaAttachment = attachment as? MediaAttachment else { return }
        self.presenter.selected(mediaAttachment: mediaAttachment, in: textView)
    }
    
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        guard let mediaAttachment = attachment as? MediaAttachment else { return }
        self.presenter.deselected(mediaAttachment: mediaAttachment, in: textView)
    }
}

extension CreatePostViewController: UINavigationControllerDelegate { }

extension CreatePostViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
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
        var attachmentIdentifier: String = ""
        self.presenter.upload(image: image)
            .catchError {  [weak self] (error) -> Observable<Progress> in
                if let attachment = self?.richTextView.attachment(withId: attachmentIdentifier) {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center
                    print(error.localizedDescription)
                    attachment.message = NSAttributedString(string: "UPLOAD_ERROR_POST_IMG".localized(), attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .semibold), .paragraphStyle: paragraphStyle, .foregroundColor: UIColor.white])
                    attachment.overlayImage = #imageLiteral(resourceName: "sync-alt")
                    self?.richTextView.refresh(attachment)
                }
                return .empty()
        }
        .subscribe(onNext: { [weak self] (progress) in
            guard let source = progress.userInfo[.imageSourceKey] as? DefaultImageUsecase.SourceImage else { return }
            if source == .local {
                guard let url = progress.userInfo[.imageURLKey] as? URL, let selectedRange = self?.richTextView.selectedRange, let attachment = self?.richTextView.replaceWithImage(at: selectedRange, sourceURL: url, placeHolderImage: image) else { return }
                attachment.size = .full
                attachment.alignment = .center
                attachment.message = .init(string: "LOADING_MESSEAGE".localized(), attributes: [.font: UIFont.systemFont(ofSize: 15.0, weight: .semibold), .foregroundColor: UIColor.white])
                attachmentIdentifier = attachment.identifier
                if let attachmentRange = self?.richTextView.textStorage.ranges(forAttachment: attachment).first {
//                    self?.richTextView
                    self?.richTextView.setLink(url, inRange: attachmentRange)
                }
                self?.richTextView.becomeFirstResponder()
            } else {
                guard let attachment = self?.richTextView.attachment(withId: attachmentIdentifier) as? ImageAttachment else { return }
                if progress.fractionCompleted >= 1.0 {
                    attachment.progress = nil
                    if let url = progress.userInfo[.imageURLKey] as? URL, let attachmentRange = self?.richTextView.textStorage.ranges(forAttachment: attachment).first {
                        attachment.message = nil
                        self?.richTextView.replaceWithImage(at: attachmentRange, sourceURL: url, placeHolderImage: image, identifier: attachmentIdentifier).alignment = .center
                        self?.richTextView.removeLink(inRange: attachmentRange)
                        self?.richTextView.selectedRange = .init(location: self?.richTextView.attributedText.length ?? 0, length: 0)
                        
                    }
                } else {
                    attachment.progress = progress.fractionCompleted
                }
                self?.richTextView.refresh(attachment, overlayUpdateOnly: true)
            }
        }).disposed(by: self.disposeBag)
    }
}
