import UIKit
import RxSwift
import SnapKit

class BaseViewController: UIViewController {
    
    var disposeBag = DisposeBag()
    
    var isShowBackBtn = true
    
    private let titleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
    var barColor = UIColor(red: 90/255, green: 164/255, blue: 204/255, alpha: 1.0)
    
    class var storyboardName: String {
        let endIndex = name.index(name.endIndex, offsetBy: -2)
        return String(name[..<endIndex])
    }
    
    class var identifier: String {
        return self.name
    }
    
    //MARK: - Router
    func getViewControllerFromStorybroad(storybroadName: String,identifier: String) -> UIViewController{
        let storybroad = UIStoryboard(name: storybroadName, bundle: Bundle.main)
        return storybroad.instantiateViewController(withIdentifier: identifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //let color = UIColor(red: 12/255, green: 123/255, blue: 254/255, alpha: 1.0)
        self.navigationController?.navigationBar.barTintColor = barColor
        
        // Set Title text color
        let textAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
        self.navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        // Set close soft keyboard when user click out of TextField
        self.hideKeyboardOnTap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isShowBackBtn {
            self.setBackIcon()
        }
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
    
    func setBackIcon() {
        navigationItem.leftBarButtonItem = barButton(imageName: "ic_back_white", selector: #selector(self.onBackTapped))
    }
    
    func setTitleNavigationBar(title: String) {
        navigationItem.title = title
    }
    
    @objc func onBackTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK - Close soft keyboard when user click out of TextField
    private func hideKeyboardOnTap(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap);
    }

    @objc private func hideKeyboard(){
        self.view.endEditing(true);
    }
}
