//
//  ContentView.swift
//  Happiness Checklist
//
//  Created by Christine Chen on 9/6/25.
//

import SwiftUI
import CoreData
import UIKit
import StoreKit
import PhotosUI
import Photos

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel: DailyEntryViewModel
    @State private var showingAbout: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var showCongrats: Bool = false


    enum Category: Identifiable {
        case gratitude, kindness, connection, meditation, savor, exercise, sleep
        
        var id: String {
            switch self {
            case .gratitude: return "gratitude"
            case .kindness: return "kindness"
            case .connection: return "connection"
            case .meditation: return "meditation"
            case .savor: return "savor"
            case .exercise: return "exercise"
            case .sleep: return "sleep"
            }
        }
    }
    @State private var editingCategory: Category? = nil
    @State private var photoToPreview: UIImage? = nil
    @State private var photoToDelete: Photo? = nil
    @State private var showingPhotoPreview: Bool = false
    @State private var showingCategoryInfo: Category? = nil
    @State private var selectedPhotoItems: [Category: PhotosPickerItem] = [:]

    init(viewModel: DailyEntryViewModel = DailyEntryViewModel(context: PersistenceController.shared.container.viewContext)) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private func isCategoryCompleted(_ category: Category) -> Bool {
        switch category {
        case .gratitude: return viewModel.isGratitudeChecked
        case .kindness: return viewModel.isKindnessChecked
        case .connection: return viewModel.isConnectionChecked
        case .meditation: return viewModel.isMeditationChecked
        case .savor: return viewModel.isSavoryChecked
        case .exercise: return viewModel.isExerciseChecked
        case .sleep: return viewModel.isSleepChecked
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 16) {
                VStack(spacing: 4) {
                    HStack {
                        Button(action: viewModel.goToPreviousDay) {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!viewModel.hasPreviousEntry)
                        Spacer()
                        Text(viewModel.selectedDate, style: .date)
                        Spacer()
                    }
                    HStack(spacing: 4) {
                        let categories: [Category] = [.gratitude, .kindness, .connection, .meditation, .savor, .exercise, .sleep]
                        ForEach(categories, id: \.id) { category in
                            if isCategoryCompleted(category), let logoImage = UIImage(named: "Logo") {
                                Image(uiImage: logoImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Form {
                    categorySection(title: "Gratitude", category: .gratitude, isChecked: viewModel.isGratitudeChecked)
                    categorySection(title: "Kindness", category: .kindness, isChecked: viewModel.isKindnessChecked)
                    categorySection(title: "Connection", category: .connection, isChecked: viewModel.isConnectionChecked)
                    categorySection(title: "Meditation", category: .meditation, isChecked: viewModel.isMeditationChecked)
                    categorySection(title: "Savor", category: .savor, isChecked: viewModel.isSavoryChecked)
                    categorySection(title: "Exercise", category: .exercise, isChecked: viewModel.isExerciseChecked)
                    categorySection(title: "Sleep", category: .sleep, isChecked: viewModel.isSleepChecked)
                }
                .scrollContentBackground(.hidden)
            }
            }
            .navigationTitle("Happiness")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.selectedDate) { _ in
                viewModel.loadEntry(for: viewModel.selectedDate)
                editingCategory = nil
            }
            .onChange(of: selectedPhotoItems) { items in
                for (category, item) in items {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            let tempIdentifier = UUID().uuidString
                            await MainActor.run {
                                viewModel.addPhotoAsset(tempIdentifier, category: key(for: category))
                                viewModel.setTempImageData(data, for: tempIdentifier)
                            }
                        }
                        await MainActor.run {
                            selectedPhotoItems[category] = nil
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                if viewModel.isTodaySelected { viewModel.save() }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isTodaySelected {
                        Button("Save") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            // Check if we're completing a category
                            let currentCategory = editingCategory
                            let wasIncomplete = currentCategory.map { category in
                                switch category {
                                case .gratitude: return !viewModel.isGratitudeChecked
                                case .kindness: return !viewModel.isKindnessChecked
                                case .connection: return !viewModel.isConnectionChecked
                                case .meditation: return !viewModel.isMeditationChecked
                                case .savor: return !viewModel.isSavoryChecked
                                case .exercise: return !viewModel.isExerciseChecked
                                case .sleep: return !viewModel.isSleepChecked
                                }
                            } ?? false
                            
                            viewModel.save()
                            editingCategory = nil
                            
                            // Show congrats only if we just completed a category
                            if wasIncomplete, let category = currentCategory {
                                let isNowComplete: Bool
                                switch category {
                                case .gratitude: isNowComplete = viewModel.isGratitudeChecked
                                case .kindness: isNowComplete = viewModel.isKindnessChecked
                                case .connection: isNowComplete = viewModel.isConnectionChecked
                                case .meditation: isNowComplete = viewModel.isMeditationChecked
                                case .savor: isNowComplete = viewModel.isSavoryChecked
                                case .exercise: isNowComplete = viewModel.isExerciseChecked
                                case .sleep: isNowComplete = viewModel.isSleepChecked
                                }
                                
                                if isNowComplete {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showCongrats = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        withAnimation(.easeOut(duration: 0.25)) { showCongrats = false }
                                    }
                                }
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("About") { showingAbout = true }
                        Button("Feedback") { requestAppReview() }
                        Button(role: .destructive) { showingDeleteAlert = true } label: { Text("Delete All Data") }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
            .onAppear {
                UITableView.appearance().backgroundColor = .clear
                UITableViewCell.appearance().backgroundColor = .clear
            }
            .sheet(isPresented: $showingAbout) {
                VStack(spacing: 12) {
                    if let logoImage = UIImage(named: "Logo") {
                        Image(uiImage: logoImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                    }
                    Text("Happiness Checklist").font(.headline)
                    Text(appVersionString()).font(.subheadline)
                    Text("Complete daily happiness actions to boost your well-being.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("Inspired by Yale’s ‘The Science of Well-Being’ course by Dr. Laurie Santos — Yale’s most popular class in 300+ years — which covers what really drives happiness (and common misconceptions), how our minds mispredict well-being (biases and hedonic adaptation), and evidence-based ‘rewirements’ like practicing gratitude and kindness, building social connection, savoring, mindfulness/meditation, prioritizing sleep and exercise, and making better choices to boost day-to-day well-being.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Close") { showingAbout = false }
                        .padding(.top, 8)
                }
                .padding()
                .presentationDetents([.medium])
            }
            .alert("Delete All Data?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { viewModel.deleteAllData(); editingCategory = nil }
            } message: {
                Text("This will erase all saved entries and cannot be undone.")
            }
            .overlay(
                Group {
                    if showCongrats {
                        CongratsAlertView(message: "Entry saved for today.")
                    }
                }
            )
            .sheet(item: Binding<Category?>(
                get: { showingCategoryInfo },
                set: { showingCategoryInfo = $0 }
            )) { category in
                CategoryInfoView(category: category)
            }
        }
    }

    private func displayText(for category: Category) -> String {
        switch category {
        case .gratitude: return viewModel.entry?.gratitude ?? ""
        case .kindness: return viewModel.entry?.kindness ?? ""
        case .connection: return viewModel.entry?.connection ?? ""
        case .meditation: return viewModel.entry?.meditation ?? ""
        case .savor: return viewModel.entry?.savory ?? ""
        case .exercise: return viewModel.entry?.exercise ?? ""
        case .sleep: return viewModel.entry?.sleep ?? ""
        }
    }

    private func textBinding(for category: Category) -> Binding<String> {
        Binding<String>(
            get: { displayText(for: category) },
            set: { newValue in
                guard viewModel.isTodaySelected else { return }
                viewModel.ensureTodayEntry()
                switch category {
                case .gratitude: viewModel.entry?.gratitude = newValue
                case .kindness: viewModel.entry?.kindness = newValue
                case .connection: viewModel.entry?.connection = newValue
                case .meditation: viewModel.entry?.meditation = newValue
                case .savor: viewModel.entry?.savory = newValue
                case .exercise: viewModel.entry?.exercise = newValue
                case .sleep: viewModel.entry?.sleep = newValue
                }
            }
        )
    }

    @ViewBuilder
    private func categorySection(title: String, category: Category, isChecked: Bool) -> some View {
        Section(header: HStack {
            if isChecked {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            } else {
                Image(systemName: "circle").foregroundColor(.secondary)
            }
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            Button(action: { showingCategoryInfo = category }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }) {
            if viewModel.isTodaySelected && editingCategory == category {
                TextEditor(text: textBinding(for: category))
                    .frame(minHeight: UIFont.preferredFont(forTextStyle: .body).lineHeight * 2)
            } else {
                let text = displayText(for: category)
                Group {
                    if text.isEmpty && viewModel.isTodaySelected {
                        Text("Enter description").foregroundColor(.secondary).italic()
                    } else {
                        Text(text)
                    }
                }
                .onTapGesture { if viewModel.isTodaySelected { editingCategory = category } }
            }

            // Photos row
            photosRow(for: category)
        }
    }

    @ViewBuilder
    private func photosRow(for category: Category) -> some View {
        let photos = viewModel.photos.filter { $0.category == key(for: category) }
        HStack(spacing: 12) {
            if viewModel.isTodaySelected && photos.count < 3 {
                PhotosPicker(selection: Binding(
                    get: { selectedPhotoItems[category] },
                    set: { selectedPhotoItems[category] = $0 }
                ), matching: .images) {
                    Image(systemName: "photo")
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(photos, id: \.self) { p in
                        AsyncImage(photo: p, viewModel: viewModel) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(8)
                                .onTapGesture {
                                    photoToPreview = image
                                    photoToDelete = p
                                    showingPhotoPreview = true
                                }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPhotoPreview) {
            if let img = photoToPreview {
                NavigationView {
                    VStack {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .navigationTitle("Photo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showingPhotoPreview = false
                                photoToPreview = nil
                                photoToDelete = nil
                            }
                        }
                        if viewModel.isTodaySelected, let photoToDelete = photoToDelete {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(role: .destructive) {
                                    viewModel.deletePhoto(photoToDelete)
                                    showingPhotoPreview = false
                                    photoToPreview = nil
                                    self.photoToDelete = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func key(for category: Category) -> String {
        switch category {
        case .gratitude: return "gratitude"
        case .kindness: return "kindness"
        case .connection: return "connection"
        case .meditation: return "meditation"
        case .savor: return "savor"
        case .exercise: return "exercise"
        case .sleep: return "sleep"
        }
    }

    private func requestAppReview() {
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func appVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "Version \(version) (\(build))"
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
