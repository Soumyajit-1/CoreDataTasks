//
//  LocalPhoto.swift
//  CoreDataTasks
//
//  Created by Sk Jasimuddin on 28/07/25.
//
import Foundation

struct LocalPhoto: Identifiable {
    let id = UUID()
    let url: URL
    let creationDate: Date
}
