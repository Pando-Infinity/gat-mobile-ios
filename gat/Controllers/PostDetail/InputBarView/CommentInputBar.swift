//
//  CommentInputBar.swift
//  gat
//
//  Created by jujien on 5/8/20.
//  Copyright © 2020 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import InputBarAccessoryView
import RxSwift
import RxCocoa

class CommentInputBar: InputBarAccessoryView {
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let titleLabel = UILabel()
    fileprivate let replyView = InputBarButtonItem()
    fileprivate let cancelView = InputBarButtonItem()
    
    var insertBookPrefixHandler: (() -> Void)?
    var cancelReplyHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupUI()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        self.setupImageView()
        self.backgroundColor = .white
        self.setupInputTextView()
        self.setupSendButton()
        self.setupReplyView()
    }
    
    fileprivate func setupImageView() {
        let button = InputBarButtonItem()
        button.setSize(.init(width: 35.0, height: 35.0), animated: true)
        button.setImage(#imageLiteral(resourceName: "bookTagPrefix"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = .white

        let spacing = InputBarButtonItem()
        spacing.backgroundColor = .white
        spacing.setSize(.init(width: 8.0, height: 35.0), animated: true)
        
        self.setLeftStackViewWidthConstant(to: 43.0, animated: true)
        
        self.setStackViewItems([button, spacing], forStack: .left, animated: true)
        
        button.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.insertBookPrefixHandler?()
        })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func setupInputTextView() {
        self.backgroundView.backgroundColor = .white
        self.contentView.backgroundColor = .white
        self.inputTextView.backgroundColor = .white
        self.inputTextView.placeholderTextColor = #colorLiteral(red: 0.6712639928, green: 0.6712799668, blue: 0.6712713838, alpha: 1)
        self.inputTextView.placeholder = "WRITE_YOUR_COMMENT_POST".localized()
        self.inputTextView.layer.borderColor = #colorLiteral(red: 0.8823529412, green: 0.8980392157, blue: 0.9019607843, alpha: 1)
        self.inputTextView.layer.borderWidth = 1.0
        self.inputTextView.layer.cornerRadius = 16.0
        self.inputTextView.layer.masksToBounds = true
        self.inputTextView.contentInset.left = 8.0
        self.inputTextView.contentInset.right = 8.0
        self.shouldAutoUpdateMaxTextViewHeight = false
        self.maxTextViewHeight = 120.0
        self.topStackView.backgroundColor = .white
        self.leftStackView.backgroundColor = .white
        self.rightStackView.backgroundColor = .white
        self.bottomStackView.backgroundColor = .white
    }
    
    fileprivate func setupSendButton() {
        self.sendButton.setAttributedTitle(.init(string: "POST_ARTICLE_TITLE".localized(), attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 1)]), for: .normal)
        self.sendButton.setAttributedTitle(.init(string: "POST_ARTICLE_TITLE".localized(), attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 1)]), for: .disabled)
        self.sendButton.setSize(.init(width: 40.0, height: 40.0), animated: true)
    }
    
    fileprivate func setupReplyView() {
        self.replyView.backgroundColor = .paleBlue
        self.replyView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(16.0)
        }
        self.replyView.setSize(.init(width: UIScreen.main.bounds.width - 45.0, height: 32.0), animated: true)
        self.replyView.frame.size = .init(width: UIScreen.main.bounds.width, height: 32.0)
        self.cancelView.setImage(#imageLiteral(resourceName: "timesCircle"), for: .normal)
        self.cancelView.backgroundColor = .paleBlue
        self.cancelView.setSize(.init(width: 45.0, height: 32.0), animated: true)
        self.cancelView.rx.tap.bind { [weak self] _ in
            guard let view = self else { return }
            view.cancelReplyHandler?()
            view.replyView.removeFromSuperview()
            view.cancelView.removeFromSuperview()
            view.topStackView.layoutIfNeeded()
            self?.inputTextView.resignFirstResponder()
            
        }
        .disposed(by: self.disposeBag)
    }
    
    func reply(name: String) {
        let text = String(format: "REPLY_COMMENT_USER_TITLE".localized(), name)
        let attributed = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 12.0), .foregroundColor: UIColor.brownGrey])
        attributed.addAttribute(.font, value: UIFont.systemFont(ofSize: 12.0, weight: .semibold), range: (text as NSString).range(of: name))
        self.titleLabel.attributedText = attributed
        self.topStackView.axis = .horizontal
        self.setStackViewItems([self.replyView, self.cancelView], forStack: .top, animated: true)
    }
    
    func hideReply() {
        self.replyView.removeFromSuperview()
        self.cancelView.removeFromSuperview()
        self.topStackView.layoutIfNeeded()
        
    }
}
