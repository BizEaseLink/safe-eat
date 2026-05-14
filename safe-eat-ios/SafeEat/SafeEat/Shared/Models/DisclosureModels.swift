import Foundation

struct DisclosureItem: Decodable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let sortOrder: Int
    let updatedAt: String?
}
