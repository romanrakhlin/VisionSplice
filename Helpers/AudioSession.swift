//
//  AudioSession.swift
//
//
//  Created by Roman Rakhlin on 2/5/24.
//

import AVFoundation

struct AudioSession {
    static let session: AVAudioSession = .sharedInstance()

    static var isMuted: Bool { session.outputVolume == 0 }

    static var isRecordingStereo: Bool {
        #if RECORD_STEREO
        return true
        #else
        return false
        #endif
    }

    static func activate() throws {
        try session.setActive(true)
    }

    static func deactivate() throws {
        try session.setActive(false)
    }

    static func prepareForVideoRecording() throws {
        try session.setMode(.videoRecording)
    }

    static func setupForRecording() throws {
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [
                .defaultToSpeaker,
                .allowBluetooth,
                .duckOthers,
            ]
        )
        try activate()

        selectPreferredInput(.builtInMic)
        setStereoRecordingEnabled(isRecordingStereo)
    }

    static func setupForPlayback() throws {
        try session.setCategory(
            .playback,
            mode: .moviePlayback,
            options: [
                .duckOthers,
            ]
        )
        try activate()
    }

    static func selectPreferredInput(_ portType: AVAudioSession.Port) {
        guard let availableInputs = session.availableInputs,
              let selectedInput = availableInputs.first(where: { $0.portType == portType })
        else {
            print("[AudioSession] Input type is unavailable: \(portType)")
            return
        }

        do {
            try session.setPreferredInput(selectedInput)
        } catch {
            print("[AudioSession] Failed to set preferred input: \(selectedInput)")
        }
    }

    private static func setupInput(
        orientation: AVAudioSession.Orientation,
        polarPattern: AVAudioSession.PolarPattern
    ) {
        // Find the built-in microphone input's data sources,
        // and select the one that matches the specified name.
        guard
            let micInput = session.preferredInput,
//            let micInput = session.availableInputs?.first(where: { $0.portType == .builtInMic}),
            let selectedDataSource = micInput.dataSources?
            .first(where: { $0.orientation == orientation })
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

        if let inputDataSource = session.inputDataSource,
           let polarPattern = inputDataSource.selectedPolarPattern
        {
            print("[AudioSession] Selected input: \(inputDataSource) with polar pattern: \(polarPattern.rawValue))")
        }
    }

    private static func setStereoRecordingEnabled(_ isStereoRecordingEnabled: Bool) {
        setupInput(
            orientation: isStereoRecordingEnabled ? .front : .bottom,
            polarPattern: isStereoRecordingEnabled ? .stereo : .omnidirectional
        )
    }
}
