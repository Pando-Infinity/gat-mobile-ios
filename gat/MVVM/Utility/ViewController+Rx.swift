import Foundation
import RxSwift
import RxCocoa
import MBProgressHUD

extension Reactive where Base: UIViewController {
    
//    var error: Binder<Error> {
//        return Binder(base) { viewController, error in
//            viewController.showError(message: error.localizedDescription)
//        }
//    }
    
    var error: Binder<Error> {
        return Binder(base) { viewController, error in
            if let err = error as? BaseError {
                viewController.showError(message: err.errorMessage ?? "")
            } else {
                viewController.showError(message: error.localizedDescription)
            }
        }
    }
    
    var isLoading: Binder<Bool> {
        return Binder(base) { viewController, isLoading in
            if isLoading {
                let hud = MBProgressHUD.showAdded(to: viewController.view, animated: true)
                hud.offset.y = -30
            } else {
                MBProgressHUD.hide(for: viewController.view, animated: true)
            }
        }
    }
}
