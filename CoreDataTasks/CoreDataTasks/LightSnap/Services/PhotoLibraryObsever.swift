//
//  PhotoLibraryObsever.swift
//  CoreDataTasks
//
//  Created by Sk Jasimuddin on 28/07/25.
//

import Photos
import UIKit
import SwiftUI

class PhotoPermissionManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    
    static let shared = PhotoPermissionManager()
    
    init(){
        requestPermission()
    }

    func requestPermission() {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch currentStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    self?.isAuthorized = (status == .authorized || status == .limited)
                }
            }
        case .denied, .restricted:
            // Show alert to guide user to settings
            DispatchQueue.main.async {
                self.showSettingsAlert()
            }
        case .authorized, .limited:
            isAuthorized = true
        @unknown default:
            isAuthorized = false
        }
    }
    
    func showSettingsAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        let alert = UIAlertController(
            title: "Photo Access Needed",
            message: "Please allow photo library access in Settings to use this feature.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }))

        rootVC.present(alert, animated: true, completion: nil)
    }
}
