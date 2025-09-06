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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel: DailyEntryViewModel
    @State private var showingAbout: Bool = false
    @State private var showingDeleteAlert: Bool = false

    private enum Category {
        case gratitude, kindness, connection, meditation, savor
    }
    @State private var editingCategory: Category? = nil

    init(viewModel: DailyEntryViewModel = DailyEntryViewModel(context: PersistenceController.shared.container.viewContext)) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 16) {
                HStack {
                    if viewModel.hasPreviousEntry {
                        Button(action: viewModel.goToPreviousDay) {
                            Image(systemName: "chevron.left")
                        }
                    }
                    Spacer()
                    Text(viewModel.selectedDate, style: .date)
                    Spacer()
                    Button(action: viewModel.goToNextDay) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(Calendar.current.isDateInToday(viewModel.selectedDate))
                }
                .padding(.horizontal)

                Form {
                    categorySection(title: "Gratitude", category: .gratitude, isChecked: viewModel.isGratitudeChecked)
                    categorySection(title: "Kindness", category: .kindness, isChecked: viewModel.isKindnessChecked)
                    categorySection(title: "Connection", category: .connection, isChecked: viewModel.isConnectionChecked)
                    categorySection(title: "Meditation", category: .meditation, isChecked: viewModel.isMedicationChecked)
                    categorySection(title: "Savor", category: .savor, isChecked: viewModel.isSavoryChecked)
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
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                if viewModel.isTodaySelected { viewModel.save() }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isTodaySelected {
                        Button("Save") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            viewModel.save()
                            editingCategory = nil
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
                    Text("Happiness Checklist").font(.headline)
                    Text(appVersionString()).font(.subheadline)
                    Text("Track your daily happiness actions across five categories.")
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
        }
    }

    private func displayText(for category: Category) -> String {
        switch category {
        case .gratitude: return viewModel.entry?.gratitude ?? ""
        case .kindness: return viewModel.entry?.kindness ?? ""
        case .connection: return viewModel.entry?.connection ?? ""
        case .meditation: return viewModel.entry?.medication ?? ""
        case .savor: return viewModel.entry?.savory ?? ""
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
                case .meditation: viewModel.entry?.medication = newValue
                case .savor: viewModel.entry?.savory = newValue
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
                Image(systemName: "checkmark.circle.fill").opacity(0)
            }
            Text(title)
        }) {
            if viewModel.isTodaySelected && editingCategory == category {
                TextEditor(text: textBinding(for: category))
                    .frame(minHeight: UIFont.preferredFont(forTextStyle: .body).lineHeight * 2)
            } else {
                let text = displayText(for: category)
                Group {
                    if text.isEmpty && viewModel.isTodaySelected {
                        Text("Tap to add").foregroundColor(.secondary).italic()
                    } else {
                        Text(text)
                    }
                }
                .onTapGesture { if viewModel.isTodaySelected { editingCategory = category } }
            }
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
