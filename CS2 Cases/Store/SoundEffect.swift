//
//  SoundEffect.swift
//  CS2 Cases
//
//  Short tones synthesized at runtime and played through AVAudioEngine with
//  a .playback audio session. AudioServicesPlaySystemSound (the previous
//  approach) silently obeys the Ring/Silent switch, which is almost
//  certainly why clicks weren't audible -- .playback explicitly keeps
//  playing with the switch set to silent. No bundled audio assets needed,
//  so there's nothing to source or license.
//

import AVFAudio
import Foundation
import UIKit

enum SoundEffect {
    private static let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private static let engine = AVAudioEngine()
    private static let player = AVAudioPlayerNode()
    private static var isEngineRunning = false
    private static var isPlayerAttached = false

    private static let tickBuffer = tone(frequency: 1800, duration: 0.025, volume: 0.5)
    private static let spinStartBuffer = tone(frequency: 420, duration: 0.09, volume: 0.5)
    private static let commonRevealBuffer = tone(frequency: 1000, duration: 0.1, volume: 0.6)
    private static let rareRevealBuffer = chime(frequencies: [660, 880, 1320], noteDuration: 0.11)

    private static let lightImpact: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()

    private static let mediumImpact: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()

    private static let rigidImpact: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        return generator
    }()

    private static let notification: UINotificationFeedbackGenerator = {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        return generator
    }()

    static func spinStart() {
        play(spinStartBuffer)
        mediumImpact.impactOccurred()
    }

    /// Short click played every time the reel advances onto a new item.
    static func tick() {
        play(tickBuffer)
        lightImpact.impactOccurred()
    }

    static func reveal(rarity: Rarity) {
        if rarity >= .covert {
            play(rareRevealBuffer)
            notification.notificationOccurred(.success)
        } else {
            play(commonRevealBuffer)
            rigidImpact.impactOccurred()
        }
    }

    // MARK: - Playback

    private static func play(_ buffer: AVAudioPCMBuffer) {
        startEngineIfNeeded()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
    }

    private static func startEngineIfNeeded() {
        // Check the engine's real state rather than only a cached flag: an
        // interruption (call, Siri, route change) stops the engine behind
        // our back, and a stale flag would leave the app silent forever.
        guard !(isEngineRunning && engine.isRunning) else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Fall through: haptics still fire even if the session fails
            // to activate, so this isn't fatal.
        }

        // Attaching an already-attached node raises an exception, so only
        // wire the graph up once -- retries just restart the engine.
        if !isPlayerAttached {
            engine.attach(player)
            isPlayerAttached = true
        }

        do {
            try engine.connectNode(player, to: engine.mainMixerNode, format: format)
            try engine.start()
            try player.playAudio()
            isEngineRunning = true
        } catch {
            // Leave isEngineRunning false so a later call can retry.
            isEngineRunning = false
        }
    }

    // MARK: - Tone synthesis

    private static func tone(frequency: Double, duration: Double, volume: Float) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let samples = buffer.floatChannelData![0]

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let envelope = Float(1.0 - t / duration)
            samples[frame] = Float(sin(2.0 * .pi * frequency * t)) * volume * envelope
        }
        return buffer
    }

    /// A short ascending sequence of notes, for a celebratory rare-pull sound.
    private static func chime(frequencies: [Double], noteDuration: Double) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let framesPerNote = Int(noteDuration * sampleRate)
        let totalFrames = AVAudioFrameCount(framesPerNote * frequencies.count)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames)!
        buffer.frameLength = totalFrames
        let samples = buffer.floatChannelData![0]

        var frame = 0
        for frequency in frequencies {
            for i in 0..<framesPerNote {
                let t = Double(i) / sampleRate
                let envelope = Float(1.0 - Double(i) / Double(framesPerNote))
                samples[frame] = Float(sin(2.0 * .pi * frequency * t)) * 0.6 * envelope
                frame += 1
            }
        }
        return buffer
    }
}
