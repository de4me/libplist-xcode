//
//  ViewController.swift
//  plistutilSwift
//
//  Created by DE4ME on 17.05.2023.
//

import Cocoa;
import plist;


class vMainViewController: NSViewController {
    
    @IBOutlet var convertButton: NSButton!;
    @IBOutlet var inputTextField: NSTextField!;
    @IBOutlet var outputTextField: NSTextField!;
    
    //MARK: VAR
    
    private var outputFormat: PlistFormat = .xml;
    @objc var compactValue: Bool = false;
    @objc var sortValue: Bool = false;
    
    @objc var formatValue: String {
        set {
            guard let format = PlistFormat(description: newValue) else {
                return;
            }
            self.outputFormat = format;
        }
        get {
            self.outputFormat.description;
        }
    }
    
    private var outputUrl: URL? {
        didSet {
            self.updateConvertButton();
        }
    }
    
    override var representedObject: Any? {
        didSet {
            self.updateRepresentedObject();
            self.updateConvertButton();
        }
    }
    
    //MARK: GET
    
    @objc var formatList: [String] {
        PlistFormat.allCases.map{ $0.description; };
    }
    
    private var inputUrl: URL? {
        switch self.representedObject {
        case let string as String:
            #if swift(>=5.8)
            if #available(macOS 13.0, *) {
                return URL(filePath: string)
            } else {
                return URL(fileURLWithPath: string);
            }
            #else
            return URL(fileURLWithPath: string);
            #endif
        case let url as URL:
            return url;
        default:
            return nil;
        }
    }
    
    private var convertOptions: PlistOption {
        var options: PlistOption = [];
        if self.compactValue {
            options.insert(.compact);
        }
        if self.sortValue {
            options.insert(.sort);
        }
        return options;
    }
    
    //MARK: OVERRIDE

    override func viewDidLoad() {
        super.viewDidLoad();
        self.updateConvertButton();
    }
    
    //MARK: UI
    
    private func updateRepresentedObject() {
        let string: String?;
        #if swift(>=5.8)
        if #available(macOS 13.0, *) {
            string = self.inputUrl?.path(percentEncoded: false);
        } else {
            string = self.inputUrl?.path;
        }
        #else
        string = self.inputUrl?.path;
        #endif
        self.inputTextField.objectValue = string;
    }
    
    private func updateConvertButton() {
        self.convertButton.isEnabled = self.inputUrl != nil && self.outputUrl != nil;
    }
    
    private func updateFormat() {
        guard let url = self.outputUrl else {
            return;
        }
        let format: PlistFormat;
        switch url.pathExtension.lowercased() {
        case "xml":
            format = .xml;
        case "json":
            format = .json;
        case "openstep", "ostep":
            format = .openStep;
        default:
            return;
        }
        self.willChangeValue(for: \.formatValue);
        self.outputFormat = format;
        self.didChangeValue(for: \.formatValue);
    }
    
    //MARK: ACTION
    
    @IBAction func inputBrowseClick(_ sender: Any) {
        let panel = NSOpenPanel();
        if let url = self.inputUrl {
            panel.directoryURL = url.deletingLastPathComponent();
            panel.nameFieldStringValue = url.lastPathComponent;
        }
        panel.allowsMultipleSelection = false;
        panel.canChooseDirectories = false;
        panel.canSelectHiddenExtension = true;
        guard panel.runModal() == .OK else {
            return;
        }
        guard let url = panel.url else {
            return;
        }
        self.representedObject = url;
        NSDocumentController.shared.noteNewRecentDocumentURL(url);
    }
    
    @IBAction func outputBrowseClick(_ sender: Any) {
        let panel = NSSavePanel();
        if let url = self.outputUrl {
            panel.directoryURL = url.deletingLastPathComponent();
            panel.nameFieldStringValue = url.lastPathComponent;
        }
        guard panel.runModal() == .OK else {
            return;
        }
        guard let url = panel.url else {
            return;
        }
        let string: String?;
        #if swift(>=5.8)
        if #available(macOS 13.0, *) {
            string = url.path(percentEncoded: false);
        } else {
            string = url.path;
        }
        #else
        string = url.path;
        #endif
        self.outputTextField.objectValue = string;
        self.outputUrl = url;
        self.updateFormat();
    }
    
    @IBAction func convertClick(_ sender: Any) {
        guard let input_url = self.inputUrl,
              let output_url = self.outputUrl
        else {
            return;
        }
        let operation = ConvertOperation(inputUrl: input_url, outputUrl: output_url, outputFormat: self.outputFormat, options: self.convertOptions);
        operation.completionBlock = {
            OperationQueue.main.addOperation {
                self.presentError(operation.error);
            }
        }
        operation.convert();
    }

}

