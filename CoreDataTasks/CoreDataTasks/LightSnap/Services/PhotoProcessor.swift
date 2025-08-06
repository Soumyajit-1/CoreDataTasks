//
//  CompressionService.swift
//  CoreDataTasks
//
//  Created by Sk Jasimuddin on 28/07/25.
//

//  CompressionService.swift
//  CoreDataTasks

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
            if self?.photoExists(with: asset.localIdentifier) == true {
                return
            }

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            let size = CGSize(width: 1000, height: 1000)

            manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { [weak self] image, info in
                guard let image = image, let self = self else { return }

                guard let jpegData = image.jpegData(compressionQuality: compressionQuality) else { return }

                self.extractMetadataAndSave(asset: asset, imageData: jpegData)
            }
        }
    }

    private func extractMetadataAndSave(asset: PHAsset, imageData: Data) {
        let context = self.coreDataStack.context
        let photo = Photo(context: context)

        // The 6 core attributes:
        photo.assetIdentifier = asset.localIdentifier
        photo.filename = "\(UUID().uuidString).jpg"
        photo.imageData = imageData
        photo.savedDate = Date()
        photo.creationDate = asset.creationDate

        // Optional: location name (from geocoding)
        if let location = asset.location {
            self.reverseGeocode(location: location) { locationName in
                DispatchQueue.main.async {
                    photo.location = locationName
                    self.coreDataStack.saveContext()
                }
            }
        } else {
            self.coreDataStack.saveContext()
        }
    }

    // Only keep reverseGeocode and photoExists utility methods

    private func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var components: [String] = []
                if let locality = placemark.locality { components.append(locality) }
                if let administrativeArea = placemark.administrativeArea { components.append(administrativeArea) }
                if let country = placemark.country { components.append(country) }
                completion(components.joined(separator: ", "))
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
            return false
        }
    }
}
