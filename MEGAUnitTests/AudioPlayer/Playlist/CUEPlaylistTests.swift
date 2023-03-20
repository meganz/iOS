//
//  CURPlaylistTests.swift
//  MEGAUnitTests
//
//  Created by Meler Paine on 2023/3/16.
//  Copyright © 2023 MEGA. All rights reserved.
//

import XCTest
@testable import MEGA

final class CURPlaylistTests: XCTestCase {
    
    func testCUEParse() {
        let cue = """
        REM COMMENT "CUETools generated dummy CUE sheet"
        FILE "01. Ascending Bird.flac" WAVE
          TRACK 01 AUDIO
            INDEX 01 00:00:00
        FILE "02. Rusalka, Op. 114, Act 1- Song to the Moon (Arr. Diner Bennett for Cello and Orchestra).flac" WAVE
          TRACK 02 AUDIO
            INDEX 01 00:00:00
        FILE "03. Azul- I. Paz Sulfurica.flac" WAVE
          TRACK 03 AUDIO
            INDEX 01 00:00:00
        FILE "04. Azul- II. Silencio.flac" WAVE
          TRACK 04 AUDIO
            INDEX 01 00:00:00
        FILE "05. Azul- III. Transit.flac" WAVE
          TRACK 05 AUDIO
            INDEX 01 00:00:00
        FILE "06. Azul- IV. Yrushalem.flac" WAVE
          TRACK 06 AUDIO
            INDEX 01 00:00:00
        FILE "07. Tierkreis- Leo (Arr. Shaw for Ensemble).flac" WAVE
          TRACK 07 AUDIO
            INDEX 01 00:00:00
        FILE "08. Suite from Run Rabbit Run- I. Year of the Ox (Arr. Atkinson for Orchestra).flac" WAVE
          TRACK 08 AUDIO
            INDEX 01 00:00:00
        FILE "09. Suite from Run Rabbit Run- II. Enjoy Your Rabbit (Arr. Atkinson for Orchestra).flac" WAVE
          TRACK 09 AUDIO
            INDEX 01 00:00:00
        FILE "10. Suite from Run Rabbit Run- III. Year of Our Lord (Arr. Atkinson for Orchestra).flac" WAVE
          TRACK 10 AUDIO
            INDEX 01 00:00:00
        FILE "11. Suite from Run Rabbit Run- IV. Year of the Boar (Arr. Atkinson for Orchestra).flac" WAVE
          TRACK 11 AUDIO
            INDEX 01 00:00:00
        """
        
        let parser = CUEPlaylistParser(cueContent: cue)
        let tracks = parser.tracks
        XCTAssertEqual(tracks.count, 11)
        XCTAssertEqual(tracks[0].fileName, "01. Ascending Bird.flac")
        XCTAssertEqual(tracks[0].time, 0)
    }
    
}
