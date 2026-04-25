import Foundation
import PDFKit

let args = CommandLine.arguments
if args.count < 2 {
    print("Usage: extract_pdf.swift <pdf_path>")
    exit(1)
}

let path = args[1]
let url = URL(fileURLWithPath: path)
if let pdf = PDFDocument(url: url) {
    var fullText = ""
    for i in 0..<pdf.pageCount {
        if let page = pdf.page(at: i), let text = page.string {
            fullText += "--- Page \(i+1) ---\n"
            fullText += text + "\n"
        }
    }
    print(fullText)
} else {
    print("Failed to open PDF.")
}
