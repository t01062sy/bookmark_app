import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: - Properties
    private var apiClient = BookmarkAPIClient()
    private var sharedURL: String?
    private var sharedTitle: String?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractSharedContent()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        statusLabel.text = "Processing..."
        activityIndicator.startAnimating()
    }
    
    // MARK: - Actions
    @IBAction func cancel() {
        self.extensionContext?.cancelRequest(withError: NSError(domain: "UserCancelled", code: 0, userInfo: nil))
    }
    
    @IBAction func save() {
        saveBookmark()
    }
    
    // MARK: - Content Extraction
    private func extractSharedContent() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            showError("No content to share")
            return
        }
        
        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }
            
            for attachment in attachments {
                // Handle URLs
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                self?.sharedURL = url.absoluteString
                                self?.sharedTitle = inputItem.attributedTitle?.string ?? inputItem.attributedContentText?.string
                                self?.updateUI()
                            } else if let error = error {
                                self?.showError("Failed to extract URL: \(error.localizedDescription)")
                            }
                        }
                    }
                    return
                }
                
                // Handle plain text (might contain URLs)
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
                        DispatchQueue.main.async {
                            if let text = item as? String {
                                // Try to extract URL from text
                                if let url = self?.extractURL(from: text) {
                                    self?.sharedURL = url
                                    self?.sharedTitle = text.count > url.count ? text : nil
                                    self?.updateUI()
                                } else {
                                    self?.showError("No valid URL found in shared content")
                                }
                            } else if let error = error {
                                self?.showError("Failed to extract text: \(error.localizedDescription)")
                            }
                        }
                    }
                    return
                }
            }
        }
        
        showError("No supported content type found")
    }
    
    private func extractURL(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = detector?.firstMatch(in: text, options: [], range: range),
           let url = match.url {
            return url.absoluteString
        }
        
        // Fallback: check if the text itself is a URL
        if text.hasPrefix("http://") || text.hasPrefix("https://") {
            return text
        }
        
        return nil
    }
    
    // MARK: - UI Updates
    private func updateUI() {
        if let url = sharedURL {
            statusLabel.text = "URL: \(url)"
            // Automatically save the bookmark
            saveBookmark()
        }
    }
    
    private func showError(_ message: String) {
        statusLabel.text = "Error: \(message)"
        activityIndicator.stopAnimating()
    }
    
    private func showSuccess(_ message: String) {
        statusLabel.text = message
        activityIndicator.stopAnimating()
        
        // Auto-dismiss after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    // MARK: - Bookmark Saving
    private func saveBookmark() {
        guard let urlString = sharedURL else {
            showError("No URL to save")
            return
        }
        
        statusLabel.text = "Saving bookmark..."
        activityIndicator.startAnimating()
        
        // Detect source type from URL
        let sourceType = detectSourceType(from: urlString)
        
        // Create bookmark request
        let request = CreateBookmarkRequest(
            url: urlString,
            title: sharedTitle,
            tags: nil,
            category: nil,
            sourceType: sourceType
        )
        
        Task { @MainActor in
            do {
                let response = try await apiClient.createBookmark(request)
                showSuccess("Bookmark saved successfully!")
                print("✅ Bookmark saved: \(response.titleFinal)")
            } catch {
                showError("Failed to save: \(error.localizedDescription)")
                print("❌ Save error: \(error)")
            }
        }
    }
    
    private func detectSourceType(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return "other"
        }
        
        if host.contains("youtube.com") || host.contains("youtu.be") {
            return "youtube"
        } else if host.contains("twitter.com") || host.contains("x.com") {
            return "x"
        } else if host.contains("medium.com") || host.contains("substack.com") {
            return "blog"
        } else if host.contains("github.com") {
            return "tech"
        } else {
            // Check path for common article patterns
            let path = url.path.lowercased()
            if path.contains("article") || path.contains("post") || path.contains("blog") {
                return "article"
            } else if path.contains("news") {
                return "news"
            }
        }
        
        return "other"
    }
}

// MARK: - Extensions

extension ShareViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Customize navigation bar appearance
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.tintColor = .systemBlue
            navigationBar.titleTextAttributes = [.foregroundColor: UIColor.label]
        }
    }
}