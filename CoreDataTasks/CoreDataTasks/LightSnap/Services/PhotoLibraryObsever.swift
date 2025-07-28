//
//  PhotoLibraryObsever.swift
//  CoreDataTasks
//
//  Created by Sk Jasimuddin on 28/07/25.
//

import Photos

class PhotoPermissionManager: ObservableObject {
    @Published var isAuthorized: Bool = false

    func requestPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = (status == .authorized || status == .limited)
            }
        }
    }
}
