import SwiftUI

struct PhotoGridView: View {
    @StateObject var viewModel = PhotoLibraryViewModel()
    @State private var selectedPath: String?
    @State private var showPreview = false

    let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        Group {
            if PhotoPermissionManager.shared.isAuthorized {
                if viewModel.savedPhotos.isEmpty {
                    VStack {
                        Text("No photos found.")
                        Button("Reload Photos") {
                            viewModel.loadPhotos()
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(viewModel.savedPhotos) { photo in
                                if let image = UIImage(contentsOfFile: photo.url.path) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedPath = photo.url.path
                                            showPreview = true
                                            
                                            
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Text("Allow Photo Access to view your saved photos.")
                    Button("Allow Access") {
                        PhotoPermissionManager.shared.requestPermission()
                    }
                }
                .padding()
            }
        }
        .onAppear {
            PhotoProcessor.shared.compressAndSaveRecentPhotos()
            viewModel.loadPhotos()
        }
        .sheet(isPresented: $showPreview) {
            if let selectedPath = selectedPath {
                PhotoPreviewView(imagePath: selectedPath) {
                    showPreview = false
                }
            } else {
                // Fallback view
                VStack {
                    Text("Image not available")
                    Button("Close") {
                        showPreview = false
                    }
                }
            }
        }    }
}
