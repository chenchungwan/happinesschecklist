import Foundation
import CoreData
import Photos
import UIKit

final class DailyEntryViewModel: ObservableObject {
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var entry: DailyEntry?
    @Published var hasPreviousEntry: Bool = false
    @Published var photos: [Photo] = []

    private let context: NSManagedObjectContext
    private var tempImageData: [String: Data] = [:]

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
        loadPhotos()
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

    private func hasPhotosForCategory(_ category: String) -> Bool {
        return photos.contains { $0.category == category }
    }

    var isGratitudeChecked: Bool { hasSavedText(entry?.gratitude) || hasPhotosForCategory("gratitude") }
    var isKindnessChecked: Bool { hasSavedText(entry?.kindness) || hasPhotosForCategory("kindness") }
    var isConnectionChecked: Bool { hasSavedText(entry?.connection) || hasPhotosForCategory("connection") }
    var isMeditationChecked: Bool { hasSavedText(entry?.meditation) || hasPhotosForCategory("meditation") }
    var isSavoryChecked: Bool { hasSavedText(entry?.savory) || hasPhotosForCategory("savor") }
    var isExerciseChecked: Bool { hasSavedText(entry?.exercise) || hasPhotosForCategory("exercise") }
    var isSleepChecked: Bool { hasSavedText(entry?.sleep) || hasPhotosForCategory("sleep") }

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

    // MARK: - Photos
    func loadPhotos() {
        guard let entry = entry else {
            photos = []
            return
        }
        if let set = entry.photos as? Set<Photo> {
            photos = set.sorted { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }
        } else {
            photos = []
        }
    }

    func addPhotoAsset(_ assetIdentifier: String, category: String? = nil) {
        ensureTodayEntry()
        guard let currentEntry = entry else { return }
        
        let categoryKey = category ?? "entry"
        let categoryPhotos = photos.filter { $0.category == categoryKey }
        if categoryPhotos.count >= 3 { return }

        let photo = Photo(context: context)
        photo.id = UUID()
        photo.createdAt = Date()
        photo.assetIdentifier = assetIdentifier
        photo.category = categoryKey
        photo.entry = currentEntry
        do {
            try context.save()
            loadPhotos()
        } catch {
            #if DEBUG
            print("Failed to save photo: \(error)")
            #endif
        }
    }

    func setTempImageData(_ data: Data, for identifier: String) {
        tempImageData[identifier] = data
    }

    func deletePhoto(_ photo: Photo) {
        context.delete(photo)
        do {
            try context.save()
            loadPhotos()
        } catch {
            #if DEBUG
            print("Failed to delete photo: \(error)")
            #endif
        }
    }

    func getUIImage(for photo: Photo, completion: @escaping (UIImage?) -> Void) {
        guard let identifier = photo.assetIdentifier else {
            completion(nil)
            return
        }
        
        // First check if we have temp data for this identifier
        if let data = tempImageData[identifier] {
            completion(UIImage(data: data))
            return
        }
        
        // Otherwise try to fetch from Photos library (this may fail for temp UUIDs)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            completion(nil)
            return
        }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}


