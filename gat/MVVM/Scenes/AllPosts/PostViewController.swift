//
//  PostViewController.swift
//  gat
//
//  Created by Hung Nguyen on 12/20/19.
//  Copyright © 2019 GaTBook. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class PostViewController: UIViewController {
    private let disposeBag = DisposeBag()
    
    var viewModel: PostViewModel!
    
    @IBOutlet weak var tvError: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
    }
    
    private func bindViewModel() {
        let useCase = Application.shared.networkUseCaseProvider
        viewModel = PostViewModel(useCase: useCase.makeAuthUseCase())
        //assert(viewModel != nil)
        
        let input = PostViewModel.Input(
            loadTrigger: Driver.just(())
        )
        let output = viewModel.transform(input)
        
        print("uiid of phone: \(UIDevice.current.identifierForVendor?.uuidString)")
        
        output.posts.drive(tokenBinding)
        .disposed(by: disposeBag)
        
        output.error
            .drive(rx.error)
            .disposed(by: disposeBag)
        
        output.indicator
        .drive(rx.isLoading)
        .disposed(by: disposeBag)
        
        output.indicator
        .drive(rx.isLoading)
        .disposed(by: disposeBag)
    }
    
    var tokenBinding: Binder<Token> {
        return Binder(self, binding: { (vc, token) in
            vc.tvError.text = token.token
        })
    }
    
}
