import Foundation

struct DomainActivityPoint: Codable, Identifiable {
    let id: UUID
    let date: Date
    let count: Int

    init(id: UUID = UUID(), date: Date, count: Int) {
        self.id = id
        self.date = date
        self.count = count
    }
}
