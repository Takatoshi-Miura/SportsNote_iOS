import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

struct LocalizedStrings {
    // MARK: Common
    static let cancel = "cancel".localized
    static let addPrompt = "addPrompt".localized
    
    // MARK: Group
    static let group = "group".localized
    
    // MARK: Task
    static let task = "task".localized
    
    // MARK: Note
    static let note = "note".localized
    static let practiceNote = "practiceNote".localized
    static let tournamentNote = "tournamentNote".localized
    
    // MARK: Target
    static let target = "target".localized
    static let yearlyTarget = "yearlyTarget".localized
    static let monthlyTarget = "monthlyTarget".localized
}

