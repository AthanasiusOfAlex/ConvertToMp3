//
//  main.swift
//  ConvertToMp3
//
//  Created by Louis Melahn on 11/17/16.
//  Copyright © 2016 Louis Melahn.
//
//  This file is licensed under the MIT license.
//

import Foundation


extension Path {
    
    var files: [Path] {
        
        if let result = try? self.children() {
            
            return result
            
        } else {
            
            return [Path]()
        }
        
    }
    
    var recursiveFiles: [Path] {
        
        if let result = try? self.recursiveChildren() {
            
            return result
            
        } else {
            
            return [Path]()
        }
        
    }
    
}

// MARK - Quick and dirty command line parsing

let arguments = CommandLine.arguments

switch arguments.count {
    
case 0:
    
    assertionFailure("Something went dreadfully wrong. Not even the executible name was included among the command line arguments!")
    
case 1:
    
    let executableName = Path(arguments.first!).lastComponent
    
    print("usage:")
    print("   \(executableName) files-to-convert")
    
    exit(1)
    
default: break

}

// MARK - Make file list

var fileList = [Path]()

for pattern in arguments[1...] {
    
    fileList.append(contentsOf: Path.glob(pattern))
    
}

// MARK - Quick and dirty parser

func extractNumber(file: String) -> Int? {
    
    let pattern = "[^\\d]+(\\d+)\\.(wav|3gpp|mp4)"
    let matches = file.matches(pattern)
    
    guard let match = matches.first else { return nil }
    guard match.count >= 2 else { return nil }
    
    return Int(match[1])
    
}

let asyncGroup = AsyncGroup()

for file in fileList {
    
    guard file.isFile else { continue }
    
    guard let number = extractNumber(file: file.lastComponent) else { continue }
    
    let formattedNumber = String(format: "%02d", number)
    
    
    // Get the current month in a lowercased, three-letter code
    let todaysDate = Date()
    let formatter = DateFormatter()
    
    formatter.dateFormat = "MMM"
    let currentMonth = formatter.string(from: todaysDate).lowercased()
    
    // Get the current day
    formatter.dateFormat = "dd"
    let currentDay = formatter.string(from: todaysDate)
    
    // Get the current year
    formatter.dateFormat = "YYYY"
    let currentYear = formatter.string(from: todaysDate)
    
    let newFile = "logic-\(currentYear)-\(currentMonth)-\(currentDay)-\(formattedNumber).mp3"

    // Run the file through ffmpeg.
    
    asyncGroup.background {
    
        let task = Process()
        
        task.currentDirectoryPath = Path.current.path
        task.launchPath = "/usr/local/bin/ffmpeg"
        task.arguments = [ "-v", "0", "-y", "-i", file.path, "-codec:a", "libmp3lame", "-qscale:a", "5", newFile ]
        
        print("Processing file \(file.path)...")
        task.launch()
        print("Done processing file \(file.path)...")
        
    }
    
}

asyncGroup.wait()
print("Finished processing all files.")
