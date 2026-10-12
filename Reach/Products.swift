import SwiftUI
import AVFoundation

struct FoodProduct: Decodable, Identifiable {
    var code: String?
    var product_name: String?
    var brands: String?
    var nutriments: Nutrients?
    var id: String { code ?? product_name ?? "unknown" }
    struct Nutrients: Decodable {
        var kcal: Double?
        var protein: Double?
        enum CodingKeys: String, CodingKey { case kcal = "energy-kcal_100g"; case protein = "proteins_100g" }
    }
}
struct FoodResponse: Decodable { var products: [FoodProduct]?; var product: FoodProduct?; var status: Int? }
struct ProductLookup: View {
    @Environment(\.dismiss) var dismiss
    var select: (FoodProduct) -> Void
    @State private var query = ""
    @State private var products: [FoodProduct] = []
    @State private var loading = false
    @State private var message = ""
    @State private var scan = false
    @State private var request: Task<Void, Never>?
    @State private var lastSearch = Date.distantPast
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Food name or barcode digits", text: $query).disableAutocorrection(true).accessibilityLabel("Food name or barcode digits")
                    Button("Search nutrition labels") { search() }.disabled(loading || query.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button("Scan barcode with camera") { scan = true }
                    Text("Online lookup sends only your search or barcode to Open Food Facts. Community data may be incomplete or wrong. Check it against your package before logging.").font(.caption).foregroundColor(Ink.muted)
                }
                if loading { ProgressView("Looking up food…") }
                if !message.isEmpty { Text(message).foregroundColor(Ink.muted) }
                ForEach(products) { product in
                    Button { select(product); dismiss() } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.product_name ?? "Unnamed product").foregroundColor(Ink.ivory)
                            Text(product.brands ?? "").font(.caption).foregroundColor(Ink.muted)
                            Text(product.nutriments?.kcal.map { "\(Int($0)) kcal / 100 g" } ?? "Calories missing · enter from label").font(.caption).foregroundColor(Ink.blue)
                        }
                    }
                }
                Section { Link("Data: Open Food Facts · ODbL", destination: URL(string: "https://world.openfoodfacts.org")!) }
            }.navigationTitle("Find food").toolbar { Button("Cancel") { dismiss() } }
        }.sheet(isPresented: $scan) { BarcodeScanner { code in query = code; scan = false; search() } }
            .onDisappear { request?.cancel() }
    }
    func search() {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        guard Date().timeIntervalSince(lastSearch) >= 7 else { message = "Wait a few seconds before searching again."; return }
        lastSearch = Date(); loading = true; message = ""; products = []; request?.cancel()
        let barcode = term.allSatisfy(\.isNumber) && (8...14).contains(term.count)
        var parts = URLComponents(string: barcode ? "https://world.openfoodfacts.org/api/v2/product/\(term).json" : "https://world.openfoodfacts.org/cgi/search.pl")!
        parts.queryItems = [URLQueryItem(name: "fields", value: "code,product_name,brands,nutriments")]
        if !barcode { parts.queryItems! += [URLQueryItem(name: "search_terms", value: term), URLQueryItem(name: "search_simple", value: "1"), URLQueryItem(name: "action", value: "process"), URLQueryItem(name: "json", value: "1"), URLQueryItem(name: "page_size", value: "15")] }
        guard let url = parts.url else { loading = false; return }
        request = Task { @MainActor in
            do {
                var req = URLRequest(url: url); req.timeoutInterval = 20
                req.setValue("REACH-iOS/1.0 (personal nutrition journal)", forHTTPHeaderField: "User-Agent")
                let (bytes, response) = try await URLSession.shared.data(for: req)
                guard !Task.isCancelled else { return }
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { message = "Food lookup is temporarily unavailable. You can still enter your label manually."; loading = false; return }
                let result = try JSONDecoder().decode(FoodResponse.self, from: bytes)
                products = (result.products ?? result.product.map { [$0] } ?? []).filter { p in
                    guard let kcal = p.nutriments?.kcal else { return true }
                    return kcal.isFinite && (0...1000).contains(kcal)
                }
                if products.isEmpty { message = "No matching label found. Enter your package values manually." }
                loading = false
            } catch {
                guard !Task.isCancelled else { return }
                loading = false; message = "Couldn’t reach the food database. Manual logging works offline."
            }
        }
    }
}

struct BarcodeScanner: UIViewControllerRepresentable {
    var found: (String) -> Void
    func makeUIViewController(context: Context) -> ScanController { let controller = ScanController(); controller.found = found; return controller }
    func updateUIViewController(_ controller: ScanController, context: Context) {}
    static func dismantleUIViewController(_ controller: ScanController, coordinator: ()) { controller.stop() }
}
final class ScanController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    let queue = DispatchQueue(label: "app.reach.barcode")
    var found: ((String) -> Void)?
    var preview: AVCaptureVideoPreviewLayer?
    var delivered = false
    private var cancelled = false
    let label = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .black
        label.text = "Point the camera at a food barcode"; label.textColor = .white; label.textAlignment = .center; label.numberOfLines = 0
        label.frame = CGRect(x: 20, y: 60, width: 300, height: 90); view.addSubview(label)
        AVCaptureDevice.requestAccess(for: .video) { [weak self] allowed in
            guard let self else { return }
            if allowed { self.queue.async { self.configure() } }
            else { DispatchQueue.main.async { self.label.text = "Camera access is unavailable. Close this sheet and enter the barcode digits, or allow Camera in iPhone Settings." } }
        }
    }
    func configure() {
        guard !cancelled else { return }
        guard let device = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            DispatchQueue.main.async { self.label.text = "No camera available. Enter the barcode digits instead." }; return
        }
        session.beginConfiguration(); session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { session.commitConfiguration(); return }
        session.addOutput(output); output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce]
        session.commitConfiguration()
        DispatchQueue.main.async {
            let layer = AVCaptureVideoPreviewLayer(session: self.session); layer.videoGravity = .resizeAspectFill; layer.frame = self.view.bounds
            self.view.layer.insertSublayer(layer, at: 0); self.preview = layer
        }
        session.startRunning()
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); preview?.frame = view.bounds; label.frame = CGRect(x: 24, y: 45, width: view.bounds.width - 48, height: 100) }
    func stop() { queue.async { [weak self] in self?.cancelled = true; self?.session.stopRunning() } }
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !delivered, let code = (objects.first as? AVMetadataMachineReadableCodeObject)?.stringValue else { return }
        delivered = true; stop(); UINotificationFeedbackGenerator().notificationOccurred(.success); found?(code)
    }
}
