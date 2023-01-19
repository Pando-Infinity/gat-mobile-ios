//
//  SearchSuggestionViewController.swift
//  gat
//
//  Created by Vũ Kiên on 10/05/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol SearchDelegate: class {
    var textSearch: Observable<String> { get }
    
    var activeSearch: Observable<Bool> { get }
    
    func updateTextInSearchBar(text: String)
}

class SearchSuggestionViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var firstViewControlerType: ViewControllerType = .suggest
    var onlyViewController = false
    var showGuideline = false
    let becomSearch: BehaviorRelay<Bool> = .init(value: false)
    var previousVC: UIViewController?
    var controllers: [UIViewController] = []
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let statusSearch = BehaviorSubject<Bool>(value: false)

    // MARK: - Lifetime View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.placeholder = Gat.Text.Search.SEARCH_TITLE.localized()
        switch self.firstViewControlerType {
        case .suggest: self.performSegue(withIdentifier: "showSuggest", sender: nil)
        case .search:
            self.performSegue(withIdentifier: "showSearch", sender: nil)
//            self.searchBar.becomeFirstResponder()
        }
        self.setupUI()
        self.event()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar.placeholder = Gat.Text.SEARCH_PLACEHOLDER.localized()
    }
    
    // MARK: - UI
    fileprivate func setupUI() {
        guard Repository<UserPrivate, UserPrivateObject>.shared.get() != nil, self.showGuideline else { return }
        guard let flow = GuidelineService.shared.addBook, flow.steps[0].completed, !flow.steps[1].completed else {
            self.becomSearch.filter { $0 }.subscribe(onNext: { [weak self] (_) in
                self?.searchBar.becomeFirstResponder()
            }).disposed(by: self.disposeBag)
            return
        }
        self.configTipView()
    }
    
    fileprivate func configTipView() {
        self.view.layoutIfNeeded()
        let text = String(format: Gat.Text.Guideline.SEARCH_BOOK.localized(), Gat.Text.Guideline.SEARCH_TITLE.localized())
        let attributedString = NSMutableAttributedString(string: text, attributes: [
          .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
          .foregroundColor: #colorLiteral(red: 0, green: 0.1019607843, blue: 0.2235294118, alpha: 1)
        ])
        attributedString.addAttributes([
          .font: UIFont.systemFont(ofSize: 14.0, weight: .semibold),
          .foregroundColor: #colorLiteral(red: 0.3529411765, green: 0.6431372549, blue: 0.8, alpha: 1)
        ], range: (text as NSString).range(of: Gat.Text.Guideline.SEARCH_TITLE.localized()))
        
        var preferences = EasyTipView.Preferences()
        preferences.drawing.backgroundColor = UIColor.black.withAlphaComponent(0.26)
        preferences.drawing.backgroundColorTip = .white
        preferences.drawing.shadowColor = #colorLiteral(red: 0.4705882353, green: 0.4705882353, blue: 0.4705882353, alpha: 1)
        preferences.drawing.shadowOpacity = 0.5
        preferences.drawing.arrowPosition = .top
        preferences.positioning.maxWidth = UIScreen.main.bounds.width - 32.0
        preferences.drawing.arrowHeight = 16.0
        preferences.animating.dismissOnTap = true
        
        let origin: CGPoint
        if #available(iOS 11.0, *) {
            if let contentInset = UIApplication.shared.keyWindow?.safeAreaInsets {
                if contentInset.top == .zero {
                    origin = .init(x: self.searchBar.frame.origin.x, y: UIApplication.shared.statusBarFrame.height)
                } else {
                    origin = .init(x: self.searchBar.frame.origin.x, y: contentInset.top)
                }
                self.searchBar.frame.origin.y = contentInset.top
            } else {
                origin = self.searchBar.frame.origin
            }
        } else {
            origin = self.searchBar.frame.origin
        }
        let clipPath = UIBezierPath(rect: .init(origin: origin, size: self.searchBar.frame.size))
        
        let easyTip = EasyTipView(attributed: attributedString, clipPath: clipPath, forcus: self.searchBar, preferences: preferences, delegate: self)
        easyTip.show(withinSuperview: self.view)
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.didBeginEditingSearchEvent()
        self.cancelSearchEvent()
        self.buttonClickSearchEvent()
    }
    
    fileprivate func didBeginEditingSearchEvent() {
        self.searchBar
            .rx
            .textDidBeginEditing
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.performSegue(withIdentifier: "showSearch", sender: nil)
                self?.searchBar.showsCancelButton = true
                self?.statusSearch.onNext(false)
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func cancelSearchEvent() {
        self.searchBar
            .rx
            .cancelButtonClicked
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                self?.searchBar.showsCancelButton = false
                guard let status = self?.onlyViewController else { return }
                if status {
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    self?.performSegue(withIdentifier: "showSuggest", sender: nil)
                    self?.searchBar.text = ""
                    self?.searchBar.resignFirstResponder()
                    self?.controllers.removeLast()
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func buttonClickSearchEvent() {
        self.searchBar
            .rx
            .searchButtonClicked
            .do(onNext: { [weak self] (_) in
                self?.searchBar.resignFirstResponder()
            })
            .flatMapLatest { _ in Observable<Bool>.just(true) }
            .bind(to: self.statusSearch)
            .disposed(by: self.disposeBag)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearch" {
            let vc = segue.destination as? SearchViewController
            vc?.delegate = self
            vc?.showGuideline = self.showGuideline
        }
    }
}

extension SearchSuggestionViewController: SearchDelegate {
    
    var activeSearch: Observable<Bool> {
        return self.statusSearch.asObservable()
    }
    
    var textSearch: Observable<String> {
        return self.searchBar.rx.text.orEmpty.asObservable()
    }
    
    func updateTextInSearchBar(text: String) {
        self.searchBar.text = text
        self.searchBar.resignFirstResponder()
    }
}

extension SearchSuggestionViewController {
    enum ViewControllerType {
        case suggest
        case search
    }
}

extension SearchSuggestionViewController: EasyTipViewDelegate {
    func easyTipViewDidDismiss(_ tipView: EasyTipView, forcus: Bool) {
        guard forcus else { return }
        let flow = GuidelineService.shared.addBook!
        GuidelineService.shared.complete(step: flow.steps[1])
        self.searchBar.becomeFirstResponder()
    }
}
