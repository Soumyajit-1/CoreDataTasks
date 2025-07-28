//
//  CompressionService.swift
//  CoreDataTasks
//
//  Created by Sk Jasimuddin on 28/07/25.
//

import Photos
import UIKit

class PhotoProcessor {
    static let shared = PhotoProcessor()
    
    func compressAndSaveRecentPhotos(limit: Int = 5) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let manager = PHImageManager.default()
        
        assets.enumerateObjects { asset, _, _ in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = true
            
            let size = CGSize(width: 1000, height: 1000)
            
            manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { image, _ in
                guard let image = image else { return }
                
                // Compress to JPEG
                guard let jpegData = image.jpegData(compressionQuality: 0.5) else { return }
                
                // Generate filename using asset identifier or timestamp
                let filename = "\(UUID().uuidString).jpg"
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent(filename)
                
                do {
                    try jpegData.write(to: fileURL)
                    print("Saved: \(fileURL)")
                } catch {
                    print("Failed to save image: \(error)")
                }
            }
        }
    }
}
