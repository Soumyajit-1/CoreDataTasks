//
//  CompressionService.swift
//  CoreDataTasks
//
//  Created by Sk Jasimuddin on 28/07/25.
//

import Photos
import CoreData
import CoreLocation

class PhotoProcessor {
    static let shared = PhotoProcessor()
    private let coreDataStack = CoreDataStack.shared
    
    private init() {}
    
    func compressAndSaveRecentPhotos(limit: Int = 100, compressionQuality: CGFloat = 0.5) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let manager = PHImageManager.default()
        
        assets.enumerateObjects { [weak self] asset, _, _ in
            // Check if we already have this asset
            if self?.photoExists(with: asset.localIdentifier) == true {
                print("Photo already exists: \(asset.localIdentifier)")
                return
            }
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            
            let size = CGSize(width: 1000, height: 1000)
            
            manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { [weak self] image, info in
                guard let image = image, let self = self else { return }
                
                // Compress to JPEG
                guard let jpegData = image.jpegData(compressionQuality: compressionQuality) else { return }
                
                // Extract metadata
                self.extractMetadataAndSave(asset: asset, imageData: jpegData, compressionQuality: Double(compressionQuality))
            }
        }
    }
    
    private func extractMetadataAndSave(asset: PHAsset, imageData: Data, compressionQuality: Double) {
        // Request additional metadata
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { [weak self] data, _, _, info in
            guard let self = self else { return }
            
            // Create Photo entity
            let context = self.coreDataStack.context
            let photo = Photo(context: context)
            
            // Basic info
            photo.assetIdentifier = asset.localIdentifier
            photo.filename = "\(UUID().uuidString).jpg"
            photo.imageData = imageData
            photo.savedDate = Date()
            photo.compressionQuality = compressionQuality
            
            // Asset metadata
            photo.creationDate = asset.creationDate
            photo.modificationDate = asset.modificationDate
            photo.width = Int32(asset.pixelWidth)
            photo.height = Int32(asset.pixelHeight)
            
            // Location data
            if let location = asset.location {
                photo.latitude = location.coordinate.latitude
                photo.longitude = location.coordinate.longitude
                
                // Reverse geocoding for location name
                self.reverseGeocode(location: location) { locationName in
                    DispatchQueue.main.async {
                        photo.location = locationName
                        self.coreDataStack.saveContext()
                    }
                }
            }
            
            // Extract EXIF data if available
            if let originalData = data,
               let imageSource = CGImageSourceCreateWithData(originalData as CFData, nil),
               let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                
                self.extractEXIFData(from: imageProperties, to: photo)
            }
            
            // Calculate file size
            photo.fileSize = Int64(imageData.count)
            
            // Save to Core Data
            self.coreDataStack.saveContext()
            print("Saved photo to Core Data: \(photo.filename)")
        }
    }
    
    private func extractEXIFData(from properties: [String: Any], to photo: Photo) {
        // EXIF data
        if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let isoSpeed = exifDict[kCGImagePropertyExifISOSpeedRatings as String] as? [Int], let iso = isoSpeed.first {
                photo.isoSpeed = Int32(iso)
            }
            
            if let focalLength = exifDict[kCGImagePropertyExifFocalLength as String] as? Double {
                photo.focalLength = focalLength
            }
            
            if let aperture = exifDict[kCGImagePropertyExifFNumber as String] as? Double {
                photo.aperture = aperture
            }
            
            if let shutterSpeed = exifDict[kCGImagePropertyExifExposureTime as String] as? Double {
                photo.shutterSpeed = shutterSpeed
            }
            
            if let flash = exifDict[kCGImagePropertyExifFlash as String] as? Int {
                photo.flash = flash > 0
            }
            
            if let lensModel = exifDict[kCGImagePropertyExifLensModel as String] as? String {
                photo.lensModel = lensModel
            }
        }
        
        // TIFF data (camera info)
        if let tiffDict = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            if let cameraModel = tiffDict[kCGImagePropertyTIFFModel as String] as? String {
                photo.cameraModel = cameraModel
            }
        }
    }
    
    private func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error)")
                completion(nil)
                return
            }
            
            if let placemark = placemarks?.first {
                var locationComponents: [String] = []
                
                if let locality = placemark.locality {
                    locationComponents.append(locality)
                }
                if let administrativeArea = placemark.administrativeArea {
                    locationComponents.append(administrativeArea)
                }
                if let country = placemark.country {
                    locationComponents.append(country)
                }
                
                completion(locationComponents.joined(separator: ", "))
            } else {
                completion(nil)
            }
        }
    }
    
    private func photoExists(with assetIdentifier: String) -> Bool {
        let request: NSFetchRequest<Photo> = NSFetchRequest<Photo>(entityName: "Photo")
        request.predicate = NSPredicate(format: "assetIdentifier == %@", assetIdentifier)
        request.fetchLimit = 1
        
        do {
            let count = try coreDataStack.context.count(for: request)
            return count > 0
        } catch {
            print("Error checking photo existence: \(error)")
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    func getAllPhotos() -> [Photo] {
        let request: NSFetchRequest<Photo> = NSFetchRequest<Photo>(entityName: "Photo")
        request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
        
        do {
            return try coreDataStack.context.fetch(request)
        } catch {
            print("Error fetching photos: \(error)")
            return []
        }
    }
    
    func deletePhoto(_ photo: Photo) {
        coreDataStack.context.delete(photo)
        coreDataStack.saveContext()
    }
    
    func getPhoto(by assetIdentifier: String) -> Photo? {
        let request: NSFetchRequest<Photo> = NSFetchRequest<Photo>(entityName: "Photo")
        request.predicate = NSPredicate(format: "assetIdentifier == %@", assetIdentifier)
        request.fetchLimit = 1
        
        do {
            return try coreDataStack.context.fetch(request).first
        } catch {
            print("Error fetching photo: \(error)")
            return nil
        }
    }
}
