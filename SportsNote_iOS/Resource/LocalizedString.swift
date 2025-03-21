import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

struct LocalizedStrings {
    // MARK: Common
    static let cancel = "cancel".localized
    static let save = "save".localized
    static let delete = "delete".localized
    static let addTitle = "addTitle".localized
    static let detailTitle = "detailTitle".localized
    static let addPrompt = "addPrompt".localized
    static let inputTitle = "inputTitle".localized
    static let title = "title".localized
    static let basicInfo = "basicInfo".localized
    static let select = "select".localized
    static let complete = "complete".localized
    static let sort = "sort".localized
    static let edit = "edit".localized
    
    // MARK: Color
    static let color = "color".localized
    static let red = "red".localized
    static let pink = "pink".localized
    static let orange = "orange".localized
    static let yellow = "yellow".localized
    static let green = "green".localized
    static let blue = "blue".localized
    static let purple = "purple".localized
    static let gray = "gray".localized
    static let white = "white".localized
    static let black = "black".localized
    
    // MARK: Group
    static let group = "group".localized
    static let uncategorized = "uncategorized".localized
    
    // MARK: Task
    static let task = "task".localized
    static let cause = "cause".localized
    
    // MARK: Measures
    static let measures = "measures".localized
    static let measuresPriority = "measuresPriority".localized
    static let measuresDetail = "measuresDetail".localized
    
    // MARK: Note
    static let note = "note".localized
    static let practiceNote = "practiceNote".localized
    static let tournamentNote = "tournamentNote".localized
    static let freeNote = "freeNote".localized
    static let date = "date".localized
    static let weather = "weather".localized
    static let temperature = "temperature".localized
    static let sunny = "sunny".localized
    static let cloudy = "cloudy".localized
    static let rainy = "rainy".localized
    static let condition = "condition".localized
    static let consciousness = "consciousness".localized
    static let result = "result".localized
    static let reflection = "reflection".localized
    static let purpose = "purpose".localized
    static let practiceDetail = "practiceDetail".localized
    static let searchNotes = "searchNotes".localized
    static let noNotesFound = "noNotesFound".localized
    static let detail = "detail".localized

    // MARK: Target
    static let target = "target".localized
    static let yearlyTarget = "yearlyTarget".localized
    static let monthlyTarget = "monthlyTarget".localized
    static let period = "period".localized
    static let year = "year".localized
    static let month = "month".localized
    static let notSet = "notSet".localized

    // MARK: Setting
    static let data = "data".localized
    static let dataTransfer = "dataTransfer".localized
    static let help = "help".localized
    static let howToUseThisApp = "howToUseThisApp".localized
    static let inquiry = "inquiry".localized
    static let other = "other".localized
    static let termsOfService = "termsOfService".localized
    static let privacyPolicy = "privacyPolicy".localized
    static let appVersion = "appVersion".localized
    static let termsOfServiceTitle = "TermsOfServiceTitle".localized
    static let termsOfServiceMessage = "TermsOfServiceMessage".localized
    static let checkTermsOfService = "checkTermsOfService".localized
    static let agree = "agree".localized
}

