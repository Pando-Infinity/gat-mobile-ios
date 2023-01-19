import UIKit

class BookmarkTabView: UIView {
    
    @IBOutlet weak var bookTabView: UIView!
    @IBOutlet weak var reviewTabView: UIView!
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var reviewImageView: UIImageView!
    @IBOutlet weak var bookLabel: UILabel!
    @IBOutlet weak var reviewLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectBookTab()
        self.bookLabel.text = Gat.Text.Bookmark.BOOK_BOOKMARK_TITLE.localized()
        self.reviewLabel.text = Gat.Text.Bookmark.REVIEW_BOOKMARK_TITLE.localized()
    }
    
    func selectBookTab() {
        self.bookImageView.image = #imageLiteral(resourceName: "bookmark-tab").withRenderingMode(.alwaysTemplate)
        self.bookImageView.tintColor = #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 1)
        self.bookLabel.textColor = #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 1)
        
        self.reviewImageView.image = #imageLiteral(resourceName: "review-tab").withRenderingMode(.alwaysTemplate)
        self.reviewImageView.tintColor = #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 0.5)
        self.reviewLabel.textColor = #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 0.5)
    }
    
    func selectReviewTab() {
        self.bookImageView.image = #imageLiteral(resourceName: "bookmark-tab").withRenderingMode(.alwaysTemplate)
        self.bookImageView.tintColor = #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 0.5)
        self.bookLabel.textColor = #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 0.5)
        
        self.reviewImageView.image = #imageLiteral(resourceName: "review-tab").withRenderingMode(.alwaysTemplate)
        self.reviewImageView.tintColor = #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 1)
        self.reviewLabel.textColor = #colorLiteral(red: 0.4184360504, green: 0.7035883069, blue: 0.8381054997, alpha: 1)
    }
}
