import Foundation

final class LocalHistoryStore {
    private let fileManager = FileManager.default
    private let decoder = SafeEatAPI.makeLocalDecoder()
    private let encoder = SafeEatAPI.makeLocalEncoder()

    private var historyURL: URL {
        appSupportDirectory.appendingPathComponent(AppConfig.historyFileName)
    }

    private var imageDirectoryURL: URL {
        appSupportDirectory.appendingPathComponent(AppConfig.historyImageFolder, isDirectory: true)
    }

    private var appSupportDirectory: URL {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = root.appendingPathComponent("SafeEat", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    init() {
        if !fileManager.fileExists(atPath: imageDirectoryURL.path) {
            try? fileManager.createDirectory(at: imageDirectoryURL, withIntermediateDirectories: true)
        }
    }

    func loadItems() -> [LocalHistoryItem] {
        guard let data = try? Data(contentsOf: historyURL) else {
            return []
        }
        return (try? decoder.decode([LocalHistoryItem].self, from: data)) ?? []
    }

    func append(_ item: LocalHistoryItem) {
        var current = loadItems()
        current.insert(item, at: 0)
        saveItems(current)
    }

    func update(_ item: LocalHistoryItem) {
        var current = loadItems()
        guard let index = current.firstIndex(where: { $0.id == item.id }) else { return }
        current[index] = item
        saveItems(current)
    }

    func remove(_ item: LocalHistoryItem) {
        var current = loadItems()
        current.removeAll { $0.id == item.id }
        saveItems(current)
        removeFileIfNeeded(at: item.previewImageUri)
        removeFileIfNeeded(at: item.originalImageUri)
        removeFileIfNeeded(at: item.rawImageUri)
    }

    func saveItems(_ items: [LocalHistoryItem]) {
        if let data = try? encoder.encode(items) {
            try? data.write(to: historyURL, options: [.atomic])
        }
    }

    func clearAll() {
        try? fileManager.removeItem(at: historyURL)

        if fileManager.fileExists(atPath: imageDirectoryURL.path) {
            let childURLs = (try? fileManager.contentsOfDirectory(at: imageDirectoryURL, includingPropertiesForKeys: nil)) ?? []
            for url in childURLs {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    func storageUsageBytes() -> Int64 {
        var total: Int64 = 0

        if let historyAttributes = try? fileManager.attributesOfItem(atPath: historyURL.path),
           let size = historyAttributes[.size] as? NSNumber {
            total += size.int64Value
        }

        let childURLs = (try? fileManager.contentsOfDirectory(
            at: imageDirectoryURL,
            includingPropertiesForKeys: [.fileSizeKey]
        )) ?? []
        for url in childURLs {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            total += Int64(values?.fileSize ?? 0)
        }

        return total
    }

    func saveRecognitionImages(
        recognitionId: String,
        originalImageData: Data,
        previewImageData: Data?,
        rawImageData: Data?
    ) throws -> (originalImageUri: String, previewImageUri: String?, rawImageUri: String?) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let originalURL = imageDirectoryURL.appendingPathComponent("\(recognitionId)-\(timestamp)-original.jpg")
        try originalImageData.write(to: originalURL, options: [.atomic])

        var previewURI: String?
        if let previewImageData {
            let previewURL = imageDirectoryURL.appendingPathComponent("\(recognitionId)-\(timestamp)-preview.png")
            try previewImageData.write(to: previewURL, options: [.atomic])
            previewURI = previewURL.absoluteString
        }

        var rawURI: String?
        if let rawImageData {
            let rawURL = imageDirectoryURL.appendingPathComponent("\(recognitionId)-\(timestamp)-raw.jpg")
            try rawImageData.write(to: rawURL, options: [.atomic])
            rawURI = rawURL.absoluteString
        }

        return (originalURL.absoluteString, previewURI, rawURI)
    }

    func replaceRecognitionImages(
        for item: LocalHistoryItem,
        originalImageData: Data,
        previewImageData: Data?
    ) throws {
        guard let originalURL = fileURL(from: item.originalImageUri) else {
            throw APIError.server(status: 0, message: "本地原图路径无效。")
        }

        try originalImageData.write(to: originalURL, options: [.atomic])

        if let previewImageUri = item.previewImageUri, let previewURL = fileURL(from: previewImageUri) {
            if let previewImageData {
                try previewImageData.write(to: previewURL, options: [.atomic])
            } else if fileManager.fileExists(atPath: previewURL.path) {
                try? fileManager.removeItem(at: previewURL)
            }
        }
    }

    private func removeFileIfNeeded(at uri: String?) {
        guard
            let uri,
            let fileURL = fileURL(from: uri),
            fileManager.fileExists(atPath: fileURL.path)
        else {
            return
        }

        try? fileManager.removeItem(at: fileURL)
    }

    private func fileURL(from uri: String) -> URL? {
        if let fileURL = URL(string: uri), fileURL.isFileURL {
            return fileURL
        }

        return URL(fileURLWithPath: uri)
    }
}

extension SafeEatAPI {
    static func makeLocalDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func makeLocalEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
