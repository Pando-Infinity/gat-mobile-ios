import UIKit

class BookmarkStoryboardSegue: UIStoryboardSegue {
    override func perform() {
        guard let fromVC = self.source as? BookmarkViewController else {
            return
        }
        fromVC.previousController?.willMove(toParent: nil)
        fromVC.previousController?.removeFromParent()
        fromVC.previousController?.view.removeFromSuperview()
        
        let toVC = self.destination
        if let controller = fromVC.controllers.filter({$0.className == toVC.className}).first {
            self.addController(from: fromVC, to: controller)
        } else {
            fromVC.controllers.append(toVC)
            self.addController(from: fromVC, to: toVC)
        }
    }
    
    fileprivate func addController(from: BookmarkViewController, to: UIViewController) {
        to.view.frame = from.containerView.bounds
        to.didMove(toParent: from)
        from.addChild(to)
        from.containerView.addSubview(to.view)
        from.previousController = to
    }
}
