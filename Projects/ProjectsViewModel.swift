//
//  ProjectsViewModel.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/18/24.
//

import SwiftUI
import Combine

final class ProjectsViewModel: ObservableObject {
    
    let resultsStorageWorker = CoreDataService()
    
    @Published var results: [ResultModel] = []
    
    var anyCancellable: AnyCancellable?
    
    init() {
        results = resultsStorageWorker.objects.map { ResultModel(object: $0) }
                
        anyCancellable = resultsStorageWorker.objectWillChange.sink { [weak self] _ in
            guard let self else { return }

            self.results = self.resultsStorageWorker.objects.map { ResultModel(object: $0) }
            self.objectWillChange.send()
        }
    }
    
    public func create(result: ResultModel) {
        resultsStorageWorker.create(result)
    }
    
    public func delete(result: ResultModel) {
        resultsStorageWorker.deleteObjectWith(id: result.id)
    }
}
