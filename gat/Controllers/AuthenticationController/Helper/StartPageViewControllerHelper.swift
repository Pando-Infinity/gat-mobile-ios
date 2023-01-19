//
//  LoginViewModel.swift
//  gat
//
//  Created by HungTran on 2/22/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import RxRealm

class StartPageViewControllerHelper {
    var uiViewController: UIViewController
    
    /**Dòng chứa thông tin hiện có tài khoản nào đang đăng nhập không*/
    var userExists: Observable<Result<User>>!
    
    init(dependency: (UIViewController)) {
        self.uiViewController = dependency
        
        /*Lấy dữ liệu của người dùng có ID*/
        self.userExists = User().get();
        
    }
}
