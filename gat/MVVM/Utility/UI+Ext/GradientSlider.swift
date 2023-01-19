import Foundation
import UIKit

@IBDesignable
class GradientSlider: UISlider {
    
    @IBInspectable var thumbImage: UIImage? {
        didSet {
            setThumbImage(thumbImage, for: .normal)
        }
    }
    
//    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
//        //let valueRatio = (value - self.minimumValue)
//        //print("valueRatio: \(valueRatio)")
//        //return CGRect(x: Int(valueRatio * Float(bounds.size.width - 10)) + 3, y: 0, width: 20, height: 20)
//        var xRect = 0
//        if bounds.size.width == 0 {
//            xRect = -10
//        } else if Float(bounds.size.width) == self.maximumValue {
//            xRect = Int(bounds.size.width) + 10
//        } else {
//            xRect = Int(bounds.size.width)
//        }
//        print("width: \(bounds.size.width), xRect: \(xRect)")
//
//        return CGRect(x: xRect, y: 0, width: 20, height: 20)
//    }
    
    @IBInspectable var trackHeight: CGFloat = 2
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(origin: bounds.origin, size: CGSize(width: bounds.width, height: trackHeight))
    }
    
    func setup() {
        let minTrackStartColor = UIColor(red: 73/255, green: 179/255, blue: 218/255, alpha: 1)
        let minTrackEndColor = UIColor(red: 134/255, green: 166/255, blue: 218/255, alpha: 1)
        let maxTrackColor = UIColor(red: 241/255, green: 245/255, blue: 247/255, alpha: 1)
        do {
            self.setMinimumTrackImage(try self.gradientImage(
            size: self.trackRect(forBounds: self.bounds).size,
            colorSet: [minTrackStartColor.cgColor, minTrackEndColor.cgColor]),
                                  for: .normal)
            self.setMaximumTrackImage(try self.gradientImage(
            size: self.trackRect(forBounds: self.bounds).size,
            colorSet: [maxTrackColor.cgColor, maxTrackColor.cgColor]),
                                  for: .normal)
            self.setThumbImage(thumbImage, for: .normal)
        } catch {
            self.minimumTrackTintColor = minTrackStartColor
            self.maximumTrackTintColor = maxTrackColor
        }
    }

    private func gradientImage(size: CGSize, colorSet: [CGColor]) throws -> UIImage? {
        let tgl = CAGradientLayer()
        tgl.frame = CGRect.init(x:0, y:0, width:size.width, height: size.height)
        tgl.cornerRadius = tgl.frame.height / 2
        tgl.masksToBounds = false
        tgl.colors = colorSet
        tgl.startPoint = CGPoint.init(x:0.0, y:0.5)
        tgl.endPoint = CGPoint.init(x:1.0, y:0.5)

        UIGraphicsBeginImageContextWithOptions(size, tgl.isOpaque, 0.0);
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        tgl.render(in: context)
        let image =

    UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets:
        UIEdgeInsets.init(top: 0, left: size.height, bottom: 0, right: size.height))
        UIGraphicsEndImageContext()
        return image!
    }
}


