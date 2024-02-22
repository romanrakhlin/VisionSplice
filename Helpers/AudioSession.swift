//
//  AudioSession.swift
//
//
//  Created by Roman Rakhlin on 2/5/24.
//

import AVFoundation

struct AudioSession {
    static let session: AVAudioSession = .sharedInstance()
    
    static func activate() throws {
        try session.setActive(true)
    }

    static func deactivate() throws {
        try session.setActive(false)
    }
    
    static func setupForPlayback() throws {
        try session.setCategory(.playback, mode: .moviePlayback, options: [.duckOthers])
        try activate()
    }
    
    private static func setupInput(orientation: AVAudioSession.Orientation, polarPattern: AVAudioSession.PolarPattern) {
        // Find the built-in microphone input's data sources, and select the one that matches the specified name.
        guard
            let micInput = session.preferredInput,
            let selectedDataSource = micInput.dataSources?.first(where: { $0.orientation == orientation })
        else {
            print("[AudioSession] Failed to get input data source with orientation: \(orientation)")
            return
        }

        do {
            if let supportedPolarPatterns = selectedDataSource.supportedPolarPatterns {
                if supportedPolarPatterns.contains(polarPattern) {
                    try selectedDataSource.setPreferredPolarPattern(polarPattern)
                } else {
                    print("[AudioSession] Polar pattern \(polarPattern.rawValue) is not supported for dataSource: \(selectedDataSource)")
                }
            } else {
                print("[AudioSession] Polar patterns are not supported for dataSource: \(selectedDataSource)")
            }

            try micInput.setPreferredDataSource(selectedDataSource)
            try session.setPreferredInput(micInput)

            // Update the input orientation to match the current user interface orientation.
            try session.setPreferredInputOrientation(.portrait)

        } catch {
            print("[AudioSession] Failed to select the data source: \(selectedDataSource)")
        }

        if
            let inputDataSource = session.inputDataSource,
            let polarPattern = inputDataSource.selectedPolarPattern
        {
            print("[AudioSession] Selected input: \(inputDataSource) with polar pattern: \(polarPattern.rawValue))")
        }
    }
}
