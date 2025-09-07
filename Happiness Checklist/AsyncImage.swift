import SwiftUI

struct AsyncImage: View {
    let photo: Photo
    let viewModel: DailyEntryViewModel
    let content: (UIImage) -> AnyView
    
    @State private var image: UIImage?
    
    init<Content: View>(photo: Photo, viewModel: DailyEntryViewModel, @ViewBuilder content: @escaping (UIImage) -> Content) {
        self.photo = photo
        self.viewModel = viewModel
        self.content = { AnyView(content($0)) }
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(image)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
            }
        }
        .onAppear {
            viewModel.getUIImage(for: photo) { img in
                self.image = img
            }
        }
    }
}
