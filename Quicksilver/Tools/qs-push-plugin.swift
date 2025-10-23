#!/usr/bin/env swift
import Foundation
import Dispatch

// MARK: - Constants

let DEFAULT_USER = "qs"
let DEFAULT_HOST = "https://qs0.qsapp.com/plugins"
let API_PATH     = "/admin/add.php"
let ARCHIVE_DIR  = "/var/tmp/qs-push-plugin"

// MARK: - Utilities

@discardableResult
func eprint(_ items: Any..., separator: String = " ", terminator: String = "\n") -> Int32 {
    let s = items.map { "\($0)" }.joined(separator: separator) + terminator
    fputs(s, stderr)
    return 0
}

func printUsage() {
    let usage = """
    Usage: qs-push-plugin.swift [-h|--help] [ARGS]

    This script is intended as a command-line interface to the plugin update system.
    It makes uploading plugins and application updates easier, without using the web interface.

    ARGS can be an array of paths to bundles/archives, a single path to a bundle, or nothing.
    Use `qs-push-plugin.swift <path-to-file>` to push a single file, or a glob like `*.qsplugin`.

    OPTIONS:
      -h, --help           Show this message
      -u, --user STR       User to login as (default: \(DEFAULT_USER))
      -p, --password STR   Password to use (will be asked if missing)
          --host STR       Push to a specific host (default: \(DEFAULT_HOST))
          --level INT      Override the publish level
          --secret         Override the secret parameter from the plist (bool flag)
      -c, --changes STR    Changes/changelog in HTML (required)
    """
    print(usage)
}

struct Options {
    var help = false
    var user = DEFAULT_USER
    var password: String?
    var host = DEFAULT_HOST
    var level: Int?
    var secret = false
    var changes: String?
    var files: [String] = []
}

func isSupportedFile(_ path: String) -> Bool {
    let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
    return ext == "qsplugin" || ext == "dmg"
}

// Execute a subprocess and capture stdout/stderr.
struct ProcessResult { let status: Int32; let out: Data; let err: Data }
func run(_ cmd: String, _ args: [String]) -> ProcessResult {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: cmd)
    proc.arguments = args

    let outPipe = Pipe()
    let errPipe = Pipe()
    proc.standardOutput = outPipe
    proc.standardError = errPipe

    do { try proc.run() } catch {
        return ProcessResult(status: 127, out: Data(), err: Data("Failed to run \(cmd): \(error)\n".utf8))
    }
    proc.waitUntilExit()
    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
    return ProcessResult(status: proc.terminationStatus, out: outData, err: errData)
}

// Read file contents (fatal on error to simplify script flow)
func readFileData(_ path: String) -> Data {
    let url = URL(fileURLWithPath: path)
    do { return try Data(contentsOf: url) }
    catch {
        eprint("Error: unable to read \(path): \(error)")
        exit(1)
    }
}

func fileModificationDate(_ path: String) -> Date {
    do {
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        return (attrs[.modificationDate] as? Date) ?? Date()
    } catch {
        return Date()
    }
}

func ensureDir(_ path: String) {
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
        if isDir.boolValue { return }
        try? FileManager.default.removeItem(atPath: path)
    }
    try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
}

func removeIfExists(_ path: String) {
    if FileManager.default.fileExists(atPath: path) {
        try? FileManager.default.removeItem(atPath: path)
    }
}

// Property list parsing
func parsePlist(_ data: Data) -> Any? {
    try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
}

func parsePlistFile(_ path: String) -> Any? {
    parsePlist(readFileData(path))
}

// ISO8601 formatting
let iso = ISO8601DateFormatter()

// Guess MIME by extension (fallback to octet-stream)
func mimeType(for path: String) -> String {
    let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
    switch ext {
    case "zip": return "application/zip"
    case "dmg": return "application/x-apple-diskimage"
    case "plist": return "application/xml"
    case "png": return "image/png"
    case "jpg", "jpeg": return "image/jpeg"
    default: return "application/octet-stream"
    }
}

// Multipart builder
struct FormFile {
    let name: String
    let filename: String
    let mime: String
    let data: Data
}

func buildMultipartBody(fields: [String:String], files: [FormFile], boundary: String) -> Data {
    var body = Data()
    let sep = "--\(boundary)\r\n"
    let end = "--\(boundary)--\r\n"

    for (k, v) in fields {
        body.append(sep.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(k)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(v)\r\n".data(using: .utf8)!)
    }
    for f in files {
        body.append(sep.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(f.name)\"; filename=\"\(f.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(f.mime)\r\n\r\n".data(using: .utf8)!)
        body.append(f.data)
        body.append("\r\n".data(using: .utf8)!)
    }
    body.append(end.data(using: .utf8)!)
    return body
}

func basicAuthHeader(user: String, pass: String) -> String {
    let raw = "\(user):\(pass)"
    let enc = Data(raw.utf8).base64EncodedString()
    return "Basic \(enc)"
}

// MARK: - Option parsing

var opts = Options()
let argv = CommandLine.arguments
var i = 1

func takeValue(_ label: String) -> String {
    i += 1
    if i >= argv.count {
        eprint("Missing value for \(label)")
        exit(1)
    }
    return argv[i]
}

while i < argv.count {
    let a = argv[i]
    if a == "-h" || a == "--help" {
        opts.help = true
    } else if a == "-u" || a == "--user" {
        opts.user = takeValue(a)
    } else if a == "-p" || a == "--password" {
        opts.password = takeValue(a)
    } else if a == "--host" {
        opts.host = takeValue(a)
    } else if a == "--level" {
        let v = takeValue(a)
        if let n = Int(v) { opts.level = n }
        else { eprint("Invalid integer for --level: \(v)"); exit(1) }
    } else if a == "--secret" {
        opts.secret = true
    } else if a == "-c" || a == "--changes" {
        opts.changes = takeValue(a)
    } else if a.hasPrefix("-") && a.contains("=") {
        // Support --key=value short form for a few keys
        let parts = a.split(separator: "=", maxSplits: 1).map(String.init)
        let key = parts[0]
        let val = parts[1]
        switch key {
        case "--user": opts.user = val
        case "--password": opts.password = val
        case "--host": opts.host = val
        case "--level": opts.level = Int(val)
        case "--changes": opts.changes = val
        default:
            eprint("Unknown option: \(a)")
            exit(1)
        }
    } else {
        opts.files.append(a)
    }
    i += 1
}

if opts.help {
    printUsage()
    exit(0)
}

guard let changesHTML = opts.changes, !changesHTML.isEmpty else {
    eprint("Error: You must add a changelog using the '-c' or '--changes' option.")
    printUsage()
    exit(1)
}

// If no files explicitly provided, scan CWD for *.qsplugin or *.dmg
if opts.files.isEmpty {
    let cwd = FileManager.default.currentDirectoryPath
    if let entries = try? FileManager.default.contentsOfDirectory(atPath: cwd) {
        opts.files = entries.filter { isSupportedFile($0) }
    }
}

if opts.files.isEmpty {
    eprint("No known files passed")
    exit(1)
}

// Ask for password if missing (echoed; no TTY control in stdlib-only script)
if opts.password == nil {
    print("Password for user \"\(opts.user)\": ", terminator: "")
    fflush(stdout)
    opts.password = readLine()
}
guard let password = opts.password else {
    eprint("Error: password is required.")
    exit(1)
}

// MARK: - Prepare upload target

let apiURLStr = opts.host.hasSuffix("/") ? "\(opts.host.dropLast())\(API_PATH)" : "\(opts.host)\(API_PATH)"
guard let apiURL = URL(string: apiURLStr) else {
    eprint("Invalid host URL: \(opts.host)")
    exit(1)
}

let filesToSubmit = opts.files.filter(isSupportedFile)
print("Submitting \"\(filesToSubmit.joined(separator: "\", \""))\" to \"\(apiURLStr)\"")

// Ensure archive work directory exists
ensureDir(ARCHIVE_DIR)

// MARK: - Helper: find plugin icon from Info.plist

func findPluginIconPath(bundlePath: String, info: [String:Any]) -> String? {
    guard let qs = info["QSPlugIn"] as? [String:Any] else { return nil }
    if let iconBase = qs["icon"] as? String {
        // If Info.plist provided "Foo" or "Foo.png", check common variants in Contents/Resources
        let resDir = (bundlePath as NSString).appendingPathComponent("Contents/Resources")
        let candidates: [String]
        if iconBase.lowercased().hasSuffix(".png") || iconBase.lowercased().hasSuffix(".jpg") || iconBase.lowercased().hasSuffix(".jpeg") {
            candidates = [ (resDir as NSString).appendingPathComponent(iconBase) ]
        } else {
            candidates = ["png","jpg","jpeg"].map { (resDir as NSString).appendingPathComponent("\(iconBase).\($0)") }
        }
        for c in candidates {
            if FileManager.default.fileExists(atPath: c) { return c }
        }
    }
    // (Ruby script also looked for webIcon but didn't use it directly)
    return nil
}

// MARK: - Upload loop

for file in filesToSubmit {
    guard FileManager.default.fileExists(atPath: file) else {
        print("File not found: \"\(file)\"")
        continue
    }

    var dmgMountPoint: String?
    var cleanupPaths: [String] = []

    defer {
        // Remove any temporary archives
        for p in cleanupPaths { removeIfExists(p) }
        // Remove working dir (ignore errors)
        try? FileManager.default.removeItem(atPath: ARCHIVE_DIR)
        // Detach DMG if mounted
        if let mp = dmgMountPoint {
            print("Detaching \"\(mp)\"")
            _ = run("/usr/bin/hdiutil", ["detach", mp])
        }
    }

    // Build form fields + files
    var fields: [String:String] = [
        "submit": "New",
        "changes": changesHTML
    ]
    if opts.secret { fields["secret"] = "true" }
    if let lvl = opts.level { fields["level"] = String(lvl) }

    var formFiles: [FormFile] = []

    let ext = URL(fileURLWithPath: file).pathExtension.lowercased()
    if ext == "qsplugin" {
        // Bundle: zip it with ditto and attach Info.plist + optional icon
        let baseName = ((file as NSString).lastPathComponent as NSString).deletingPathExtension
        let sanitized = baseName.replacingOccurrences(of: " ", with: "_")
        let archivePath = (ARCHIVE_DIR as NSString).appendingPathComponent("\(sanitized)-archive.zip")
        ensureDir(ARCHIVE_DIR)

        let ditto = run("/usr/bin/ditto", ["-c","-z","--keepParent", file, archivePath])
        if ditto.status != 0 {
            eprint("Error: ditto failed for \(file):", String(data: ditto.err, encoding: .utf8) ?? "")
            continue
        }
        cleanupPaths.append(archivePath)

        let infoPlistPath = (file as NSString).appendingPathComponent("Contents/Info.plist")
        guard FileManager.default.fileExists(atPath: infoPlistPath) else {
            eprint("Error: Info.plist not found at \(infoPlistPath)")
            continue
        }

        // Parse Info.plist to try and find an icon
        var iconPath: String?
        if let plistAny = parsePlistFile(infoPlistPath),
           let plist = plistAny as? [String:Any] {
            iconPath = findPluginIconPath(bundlePath: file, info: plist)
        }

        if let icon = iconPath {
            print("Sending image \"\(icon)\"")
            let imgData = readFileData(icon)
            formFiles.append(FormFile(name: "image_file",
                                      filename: (icon as NSString).lastPathComponent,
                                      mime: mimeType(for: icon),
                                      data: imgData))
            // Ruby sends image_ext as File.extname(image_file) (includes dot). Follow that:
            let dotExt = "." + URL(fileURLWithPath: icon).pathExtension
            fields["image_ext"] = dotExt
        }

        // Files: archive + Info.plist
        formFiles.append(FormFile(name: "plugin_archive_file",
                                  filename: (archivePath as NSString).lastPathComponent,
                                  mime: mimeType(for: archivePath),
                                  data: readFileData(archivePath)))

        formFiles.append(FormFile(name: "info_plist_file",
                                  filename: "Info.plist",
                                  mime: mimeType(for: infoPlistPath),
                                  data: readFileData(infoPlistPath)))

        // mod_date from the bundle itself
        fields["mod_date"] = iso.string(from: fileModificationDate(file))

    } else if ext == "dmg" {
        // Attach DMG and read Info.plist from the embedded app
        print("Attaching \"\(file)\"")
        let attach = run("/usr/bin/hdiutil", ["attach","-plist","-nobrowse", file])
        guard attach.status == 0, let plist = parsePlist(attach.out) as? [String:Any],
              let entities = plist["system-entities"] as? [[String:Any]] else {
            eprint("Failed to attach \"\(file)\"")
            continue
        }
        // Find first mount-point
        dmgMountPoint = entities.compactMap { $0["mount-point"] as? String }.first

        // Prefer using the actual mount point, not a hardcoded volume name
        guard let mount = dmgMountPoint else {
            eprint("Could not determine mount point for \(file)")
            continue
        }
        // Assume Quicksilver.app is present at the root of the volume
        let qsApp = (mount as NSString).appendingPathComponent("Quicksilver.app")
        let infoPlistPath = (qsApp as NSString).appendingPathComponent("Contents/Info.plist")
        guard FileManager.default.fileExists(atPath: infoPlistPath) else {
            eprint("Info.plist not found at \(infoPlistPath)")
            continue
        }

        // Files: the DMG itself + Info.plist
        formFiles.append(FormFile(name: "plugin_archive_file",
                                  filename: (file as NSString).lastPathComponent,
                                  mime: mimeType(for: file),
                                  data: readFileData(file)))

        formFiles.append(FormFile(name: "info_plist_file",
                                  filename: "Info.plist",
                                  mime: mimeType(for: infoPlistPath),
                                  data: readFileData(infoPlistPath)))

        fields["mod_date"] = iso.string(from: fileModificationDate(file))
        fields["is_app"] = "true"

        // NOTE: The Ruby script references a checkIsUniversalBinary(...) helper which was not defined.
        // This Swift port omits that check (there is no direct stdlib-only equivalent).
    } else {
        eprint("Unknown type \(ext) for file \(file)")
        continue
    }

    // Perform HTTP POST (multipart/form-data) with Basic Auth
    print("Submitting \"\(file)\"...", terminator: "")
    let boundary = "Boundary-\(UUID().uuidString)"
    var request = URLRequest(url: apiURL)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    request.setValue(basicAuthHeader(user: opts.user, pass: password), forHTTPHeaderField: "Authorization")
    request.httpBody = buildMultipartBody(fields: fields, files: formFiles, boundary: boundary)

    let sema = DispatchSemaphore(value: 1)
    sema.wait()
    var ok = false
    var responseBody = Data()
    URLSession.shared.dataTask(with: request) { data, resp, err in
        defer { sema.signal() }
        if let d = data { responseBody = d }
        if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode), err == nil {
            ok = true
        } else {
            ok = false
        }
    }.resume()
    sema.wait() // wait for completion

    if ok {
        print(" OK")
    } else {
        print("")
        if let s = String(data: responseBody, encoding: .utf8), !s.isEmpty {
            print(s)
        } else {
            print("Upload failed (no response body).")
        }
    }
}
