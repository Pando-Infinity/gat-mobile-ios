import SwiftyJSON

public class Challenge: BaseModel {
    var id: Int = 0
    var title: String = ""
    var description: String = ""
    var imageCover: String = ""
    var imageThumb: String = ""
    var creator: Creator? = nil
    var targetTypeId: Int = 0
    var targetModeId: Int = 0
    var targetNumber: Int = 0
    var challengeModeId: Int = 0
    var startDate: String = ""
    var endDate: String = ""
    var editions: [Book]? = nil
    var challengeProgress: ChallengeProgress? = nil
    var challengeSummary: ChallengeSummary? = nil
    
    required public init(json: JSON?, isInit: Bool) {
        super.init(json: json!)
        if isInit {
            id = json?["challengeId"].intValue ?? 0
            title = json?["title"].stringValue ?? ""
            description = json?["description"].stringValue ?? ""
            imageCover = json?["coverId"].stringValue ?? ""
            imageThumb = json?["thumbId"].stringValue ?? ""
            creator = Creator(fromJson: json?["creator"])
            targetTypeId = json?["targetTypeId"].intValue ?? 0
            targetModeId = json?["targetModeId"].intValue ?? 0
            targetNumber = json?["targetNumber"].intValue ?? 0
            challengeModeId = json?["challengeModeId"].intValue ?? 0
            startDate = json?["startDate"].stringValue ?? ""
            endDate = json?["endDate"].stringValue ?? ""
            if json?["editions"] != JSON.null {
                editions = []
                for editionElement in json?["editions"].array ?? [] {
                    let book = Book()
                    book.editionId = editionElement["editionId"].intValue
                    book.title = editionElement["title"].stringValue
                    book.author = editionElement["authorName"].stringValue
                    book.imageId = editionElement["imageId"].stringValue
                    
                    let reading = UserRelation()
                    let userReadingRelation = editionElement["userRelation"]["reading"]
                    if userReadingRelation != JSON.null {
                        reading.instanceCount = userReadingRelation["instanceCount"].intValue
                        reading.readingId = userReadingRelation["readingId"].intValue
                        print("reading.readingId: \(userReadingRelation["readingId"].intValue)")
                        reading.pageNum = userReadingRelation["pageNum"].intValue
                        reading.readPage = userReadingRelation["readPage"].intValue
                        reading.readingStatusId = userReadingRelation["readingStatusId"].intValue
                        reading.startDate = userReadingRelation["startDate"].stringValue
                        book.userRelation = reading
                    }
                    editions?.append(book)
                }
            }
            if json?["challengeProgress"] != JSON.null {
                challengeProgress = ChallengeProgress(fromJson: json?["challengeProgress"])
            }
            if json?["challengeSummary"] != JSON.null {
                challengeSummary = ChallengeSummary(fromJson: json?["challengeSummary"])
            }
        }
    }
    
    override func parseJson() {
        id = body?["challengeId"].intValue ?? 0
        title = body?["title"].stringValue ?? ""
        description = body?["description"].stringValue ?? ""
        imageCover = body?["coverId"].stringValue ?? ""
        imageThumb = body?["thumbId"].stringValue ?? ""
        creator = Creator(fromJson: body?["creator"])
        targetTypeId = body?["targetTypeId"].intValue ?? 0
        targetModeId = body?["targetModeId"].intValue ?? 0
        targetNumber = body?["targetNumber"].intValue ?? 0
        challengeModeId = body?["challengeModeId"].intValue ?? 0
        startDate = body?["startDate"].stringValue ?? ""
        endDate = body?["endDate"].stringValue ?? ""
        if body?["editions"] != JSON.null {
            editions = []
            for editionElement in body?["editions"].array ?? [] {
                let book = Book()
                book.editionId = editionElement["editionId"].intValue
                book.title = editionElement["title"].stringValue
                book.author = editionElement["authorName"].stringValue
                book.imageId = editionElement["imageId"].stringValue
                book.numberPage = editionElement["numberPage"].intValue
                
                let reading = UserRelation()
                let userReadingRelation = editionElement["userRelation"]["reading"]
                if userReadingRelation != JSON.null {
                    reading.instanceCount = userReadingRelation["instanceCount"].intValue
                    reading.readingId = userReadingRelation["readingId"].intValue
                    print("reading.readingId: \(userReadingRelation["readingId"].intValue)")
                    reading.pageNum = userReadingRelation["pageNum"].intValue
                    reading.readPage = userReadingRelation["readPage"].intValue
                    reading.readingStatusId = userReadingRelation["readingStatusId"].intValue
                    reading.startDate = userReadingRelation["startDate"].stringValue
                    book.userRelation = reading
                }
                editions?.append(book)
            }
        }
        if body?["challengeProgress"] != JSON.null {
            challengeProgress = ChallengeProgress(fromJson: body?["challengeProgress"])
        }
        if body?["challengeSummary"] != JSON.null {
            challengeSummary = ChallengeSummary(fromJson: body?["challengeSummary"])
        }
    }
}
