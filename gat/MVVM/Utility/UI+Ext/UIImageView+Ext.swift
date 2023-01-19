import UIKit
import SDWebImage

extension UIImageView {
    
    func setCircleWithBorder(imageId: String, borderWidth: CGFloat = 1, borderColor: CGColor = UIColor.white.cgColor) {
        self.layer.borderWidth = borderWidth
        self.layer.masksToBounds = false
        self.layer.borderColor = borderColor
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
        
        let url = URL(string: AppConfig.sharedConfig.setUrlImage(id: imageId, size: .z))!
        self.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "no-image.png")
        )
    }
    
    func setCircle(imageId: String) {
        self.layer.masksToBounds = false
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
        
        let url = URL(string: AppConfig.sharedConfig.setUrlImage(id: imageId))!
        self.sd_setImage(
            with: url,//URL(string: "https://fordev.gatbook.org/rest/api/common/get_image/\(imageId)"),
            placeholderImage: UIImage(named: "no-image.png")
        )
    }
    
    func setImage(imageId: String) {
        self.layer.masksToBounds = false
        self.clipsToBounds = true
        
        let url = URL(string: AppConfig.sharedConfig.setUrlImage(id: imageId, size: .z))!
        self.sd_setImage(
            with: url,//URL(string: "https://fordev.gatbook.org/rest/api/common/get_image/\(imageId)"),
            placeholderImage: UIImage(named: "no-image.png")
        )
    }
}
