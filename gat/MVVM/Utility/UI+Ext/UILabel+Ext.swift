import Foundation

extension UILabel {
//    func setHTML(html: String) {
//        do {
//            let attributedString: NSAttributedString = try NSAttributedString(data: html.data(using: .utf8)!, options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType], documentAttributes: nil)
//            self.attributedText = attributedString
//        } catch {
//            self.text = html
//        }
//    }
    var maxNumberOfLines: Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let text = (self.text ?? "") as NSString
        let textHeight = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}
