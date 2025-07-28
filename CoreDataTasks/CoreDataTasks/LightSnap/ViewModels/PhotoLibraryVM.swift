//
//  PhotoLibraryVM.swift
//  CoreDataTasks
//
//  Created by Sk Jasimuddin on 28/07/25.
//

import SwiftUI
import Foundation

class PhotoLibraryViewModel: ObservableObject {
    @Published var savedPhotos: [LocalPhoto] = []
    func loadPhotos() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let imageURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.creationDateKey])
            
            let photos: [LocalPhoto] = imageURLs
                .filter { $0.pathExtension.lowercased() == "jpg" }
                .compactMap { url in
                    let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey])
                    guard let creationDate = resourceValues?.creationDate else { return nil }
                    return LocalPhoto(url: url, creationDate: creationDate)
                }
                .sorted { $0.creationDate > $1.creationDate } // Most recent first
            
            DispatchQueue.main.async {
                self.savedPhotos = photos
            }
        } catch {
            print("Failed to read photo files: \(error)")
        }
    }
}
