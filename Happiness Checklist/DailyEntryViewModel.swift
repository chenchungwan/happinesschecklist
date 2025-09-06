import Foundation
import CoreData

final class DailyEntryViewModel: ObservableObject {
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var entry: DailyEntry?
    @Published var hasPreviousEntry: Bool = false

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        loadEntry(for: selectedDate)
    }

    func loadEntry(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        request.fetchLimit = 1
        if let result = try? context.fetch(request).first {
            entry = result
        } else {
            entry = nil
        }
        updateHasPreviousEntry(relativeTo: startOfDay)
    }

    func ensureTodayEntry() {
        let today = Calendar.current.startOfDay(for: Date())
        if entry == nil || entry?.date != today {
            let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", today as NSDate)
            request.fetchLimit = 1
            if let existing = try? context.fetch(request).first {
                entry = existing
            } else {
                let newEntry = DailyEntry(context: context)
                newEntry.date = today
                entry = newEntry
            }
        }
    }

    var isTodaySelected: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        loadEntry(for: selectedDate)
    }

    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        loadEntry(for: selectedDate)
    }

    @MainActor
    func save() {
        context.performAndWait {
            context.processPendingChanges()
            do {
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                #if DEBUG
                print("Failed to save context: \(error)")
                #endif
            }
        }
        // Refresh UI by reloading the current day's entry so computed flags update
        let dateToReload = selectedDate
        self.entry = nil
        self.loadEntry(for: dateToReload)
    }

    private func updateHasPreviousEntry(relativeTo date: Date) {
        let countRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DailyEntry")
        countRequest.predicate = NSPredicate(format: "date < %@", date as NSDate)
        let count = (try? context.count(for: countRequest)) ?? 0
        hasPreviousEntry = count > 0
    }

    private func hasSavedText(_ text: String?) -> Bool {
        guard let t = text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return false }
        if isTodaySelected && context.hasChanges { return false }
        return true
    }

    var isGratitudeChecked: Bool { hasSavedText(entry?.gratitude) }
    var isKindnessChecked: Bool { hasSavedText(entry?.kindness) }
    var isConnectionChecked: Bool { hasSavedText(entry?.connection) }
    var isMedicationChecked: Bool { hasSavedText(entry?.medication) }
    var isSavoryChecked: Bool { hasSavedText(entry?.savory) }

    @MainActor
    func deleteAllData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DailyEntry")
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDelete.resultType = .resultTypeObjectIDs
        do {
            let result = try context.execute(batchDelete) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
            try context.save()
        } catch {
            #if DEBUG
            print("Failed to delete all data: \(error)")
            #endif
        }
        loadEntry(for: selectedDate)
        updateHasPreviousEntry(relativeTo: Calendar.current.startOfDay(for: selectedDate))
    }
}


