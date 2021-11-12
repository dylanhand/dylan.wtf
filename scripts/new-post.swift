#!/usr/bin/swift

/// Generates a new post from a template.
/// Prompts user for category, title, draft status
//  based on https://github.com/jessesquires/jessesquires.com/blob/master/scripts/new-post.swift
import Foundation

print("\n=== New Dweet ===\n")
print(">", terminator: " ")

let dweet = (readLine() ?? "untitled").trimmingCharacters(in: .whitespacesAndNewlines)

let fullDateTime = ISO8601DateFormatter.string(
    from: Date(),
    timeZone: .current,
    formatOptions: [.withFullDate, .withFullTime]
)

let postTemplate = """
---
# layout: post
date: \(fullDateTime)
---
\(dweet)
"""

let postData = postTemplate.data(using: .utf8)

let dateOnly = ISO8601DateFormatter.string(
    from: Date(),
    timeZone: .current,
    formatOptions: [.withFullDate]
)

let dashedTitle = dweet.localizedLowercase.replacingOccurrences(of: " ", with: "-")
let shortenedTitle = String(dashedTitle.prefix(20))

let filePath = "./_posts/\(dateOnly)-\(shortenedTitle).md"

let result = FileManager.default.createFile(atPath: filePath, contents: postData, attributes: nil)
guard result else {
    print("🚫  Error creating file \(filePath)")
    exit(1)
} 

// TODO: check if the working copy is dirty before committing and pushing
do {
    let _ = try safeShell("git commit -am \"New Post: \(shortenedTitle)\"")
    let _ = try safeShell("git push")
} catch {
    print("Error from SafeShell: \(error)")
}

func safeShell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")

    do {
        try task.run()
    } catch { 
        throw error 
    }
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}