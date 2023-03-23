//
//  CUEPlaylistParser.swift
//  MEGA
//
//  Created by Meler Paine on 2023/3/16.
//  Copyright © 2023 MEGA. All rights reserved.
//

import Foundation

final class CUEPlaylistParser: NSObject {
    var cueContent: String
    private(set) var tracks: [CueSheetTrack] = []
    
    init(cueContent: String) {
        self.cueContent = cueContent
        super.init()
        tracks = parseCUEToTracks(cueContent: cueContent)
    }
    
    public func parseCUEToTracks(cueContent content: String) -> [CueSheetTrack] {
        var tracks = [CueSheetTrack]()
        var track: String = ""
        var fileName: String = ""
        var artist: String = ""
        var album: String = ""
        var title: String = ""
        var genre: String = ""
        var year: String = ""
        
        let lines = content.split(whereSeparator: \.isNewline)
        var trackAdded = false
        
        for line in lines {
            let scanner = Scanner(string: String(line))
            guard let command = scanner.scanUpToCharacters(from: .whitespaces) else {
                continue
            }
            
            switch command {
            case "FILE":
                trackAdded = false
                if scanner.scanString("\"") == nil { continue }
                    
                
                guard let _fileName = scanner.scanUpToString("\"") else {
                    continue
                }
                fileName = _fileName
            case "TRACK":
                trackAdded = false
                guard let _track = scanner.scanUpToCharacters(from: .whitespaces) else { continue }
                track = _track
                guard let type = scanner.scanUpToCharacters(from: .whitespaces) else { continue }
                if type != "AUDIO" {
                    continue
                }
            case "PERFORMER":
                guard scanner.scanString("\"") != nil else { continue }
                guard let _artist = scanner.scanUpToString("\"") else { continue }
                artist = _artist
            case "TITLE":
                guard scanner.scanString("\"") != nil else { continue }
                guard let _title = scanner.scanUpToString("\"") else { continue }
                if (fileName.isEmpty) {
                    album = _title
                } else {
                    title = _title
                }
            case "REM":
                guard let type = scanner.scanUpToCharacters(from: .whitespaces) else { continue }
                if type == "GENRE" {
                    if scanner.scanString("\"") != nil {
                        guard let _genre = scanner.scanUpToString("\"") else { continue }
                        genre = _genre
                    } else {
                        guard let _genre = scanner.scanUpToCharacters(from: .whitespaces) else { continue }
                        genre = _genre
                    }
                } else if type == "DATE" {
                    guard let _year = scanner.scanUpToCharacters(from: .whitespaces) else { continue }
                    year = _year
                }
            case "INDEX":
                if trackAdded || fileName.isEmpty { continue }
                guard let index = scanner.scanUpToCharacters(from: .whitespaces) else { continue }
                if Int(index) != 1 { continue }
                
                _ = scanner.scanCharacters(from: .whitespaces)
                guard let time = scanner.scanUpToCharacters(from: .whitespaces) else { continue }
                let timeParts = time.split(separator: ":")
                if timeParts.count != 3 {
                    continue
                }
                let minute = Double(timeParts[0])!
                let second = Double(timeParts[1])!
                let frame = Double(timeParts[2])!
                let seconds: Double = 60 * minute + second + frame / 75
                
                
                if track.isEmpty {
                    track = "01"
                }
                tracks.append(CueSheetTrack(fileName: fileName, track: track, artist: artist, album: album, title: title, genre: genre, year: year, startTime: seconds))
                trackAdded = true
            default:
                continue
            }
        }
        
        // calculate track end time
        if tracks.count > 1 {
            for index in 1..<tracks.count {
                let track = tracks[index]
                let previousTrack = tracks[index - 1]
                if track.fileName == previousTrack.fileName {
                    previousTrack.endTime = track.startTime
                    tracks[index - 1] = previousTrack
                }
            }
        }
        
        return tracks
    }
    
    func urlForPath(path: String, relativeTo baseFileUrl: URL) -> URL {
        let protocolRange = (path as NSString).range(of: "://")
        if (protocolRange.location != NSNotFound) {
            return URL(string: path)!
        }

        let baseUrl = baseFileUrl.deletingLastPathComponent()
        return baseUrl.appendingPathComponent(path)
    }
    
}

final class CueSheetTrack: NSObject {
    var fileName: String
    var track: String
    var artist: String
    var album: String
    var title: String
    var genre: String
    var year: String
    var startTime: Double
    var endTime: Double?
 
    init(fileName: String, track: String, artist: String, album: String, title: String, genre: String, year: String, startTime: Double, endTime: Double? = nil) {
        self.fileName = fileName
        self.track = track
        self.artist = artist
        self.album = album
        self.title = title
        self.genre = genre
        self.year = year
        self.startTime = startTime
        self.endTime = endTime
    }
}
