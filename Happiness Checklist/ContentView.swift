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
                    Section(header: HStack {
                        if viewModel.isGratitudeChecked {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        } else {
                            Image(systemName: "checkmark.circle.fill").opacity(0)
                        }
                        Text("Gratitude")
                    }) {
                        TextEditor(text: Binding(
                            get: { viewModel.entry?.gratitude ?? "" },
                            set: { newValue in
                                guard viewModel.isTodaySelected else { return }
                                viewModel.ensureTodayEntry()
                                viewModel.entry?.gratitude = newValue
                            }
                        ))
                        .disabled(!viewModel.isTodaySelected)
                        .frame(minHeight: UIFont.preferredFont(forTextStyle: .body).lineHeight * 2)
                    }
                    Section(header: HStack {
                        if viewModel.isKindnessChecked {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        } else {
                            Image(systemName: "checkmark.circle.fill").opacity(0)
                        }
                        Text("Kindness")
                    }) {
                        TextEditor(text: Binding(
                            get: { viewModel.entry?.kindness ?? "" },
                            set: { newValue in
                                guard viewModel.isTodaySelected else { return }
                                viewModel.ensureTodayEntry()
                                viewModel.entry?.kindness = newValue
                            }
                        ))
                        .disabled(!viewModel.isTodaySelected)
                        .frame(minHeight: UIFont.preferredFont(forTextStyle: .body).lineHeight * 2)
                    }
                    Section(header: HStack {
                        if viewModel.isConnectionChecked {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        } else {
                            Image(systemName: "checkmark.circle.fill").opacity(0)
                        }
                        Text("Connection")
                    }) {
                        TextEditor(text: Binding(
                            get: { viewModel.entry?.connection ?? "" },
                            set: { newValue in
                                guard viewModel.isTodaySelected else { return }
                                viewModel.ensureTodayEntry()
                                viewModel.entry?.connection = newValue
                            }
                        ))
                        .disabled(!viewModel.isTodaySelected)
                        .frame(minHeight: UIFont.preferredFont(forTextStyle: .body).lineHeight * 2)
                    }
                    Section(header: HStack {
                        if viewModel.isMedicationChecked {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        } else {
                            Image(systemName: "checkmark.circle.fill").opacity(0)
                        }
                        Text("Meditation")
                    }) {
                        TextEditor(text: Binding(
                            get: { viewModel.entry?.medication ?? "" },
                            set: { newValue in
                                guard viewModel.isTodaySelected else { return }
                                viewModel.ensureTodayEntry()
                                viewModel.entry?.medication = newValue
                            }
                        ))
                        .disabled(!viewModel.isTodaySelected)
                        .frame(minHeight: UIFont.preferredFont(forTextStyle: .body).lineHeight * 2)
                    }
                    Section(header: HStack {
                        if viewModel.isSavoryChecked {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        } else {
                            Image(systemName: "checkmark.circle.fill").opacity(0)
                        }
                        Text("Savor")
                    }) {
                        TextEditor(text: Binding(
                            get: { viewModel.entry?.savory ?? "" },
                            set: { newValue in
                                guard viewModel.isTodaySelected else { return }
                                viewModel.ensureTodayEntry()
                                viewModel.entry?.savory = newValue
                            }
                        ))
                        .disabled(!viewModel.isTodaySelected)
                        .frame(minHeight: UIFont.preferredFont(forTextStyle: .body).lineHeight * 2)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            }
            .navigationTitle("Happiness")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.selectedDate) { _ in
                viewModel.loadEntry(for: viewModel.selectedDate)
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
                    Button("Close") { showingAbout = false }
                        .padding(.top, 8)
                }
                .padding()
                .presentationDetents([.medium])
            }
            .alert("Delete All Data?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { viewModel.deleteAllData() }
            } message: {
                Text("This will erase all saved entries and cannot be undone.")
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
