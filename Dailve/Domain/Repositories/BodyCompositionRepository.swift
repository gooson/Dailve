import Foundation

protocol BodyCompositionRepository {
    func save(_ record: BodyCompositionRecord) throws
    func fetchAll() throws -> [BodyCompositionRecord]
    func fetchLatest() throws -> BodyCompositionRecord?
    func delete(_ record: BodyCompositionRecord) throws
}
