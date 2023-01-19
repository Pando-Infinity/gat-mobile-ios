import Foundation
import UIKit
import SnapKit

class CustomNavigationController: UIViewController {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let color = UIColor(red: 90/255, green: 164/255, blue: 204/255, alpha: 1.0)
        self.navigationController?.navigationBar.barTintColor = color
        
//        let image = UIImage(named: "logo")
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//        navigationItem.titleView = imageView
    }
    
    private func imageView(imageName: String) -> UIImageView {
        let logo = UIImage(named: imageName)
        let logoImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = logo
        logoImageView.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(35)
        }
        return logoImageView
    }
    
    func barImageView(imageName: String) -> UIBarButtonItem {
        return UIBarButtonItem(customView: imageView(imageName: imageName))
    }
    
    func barButton(imageName: String, selector: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: imageName), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        button.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(35)
        }
        button.addTarget(self, action: selector, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
    
    func setBackIcon(selector: Selector) {
        navigationItem.leftBarButtonItem = barButton(imageName: "ic_back_white", selector: selector)
    }
}
