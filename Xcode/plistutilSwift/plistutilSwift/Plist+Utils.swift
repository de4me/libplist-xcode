//
//  Plist+Utils.swift
//  plistutilSwift
//
//  Created by DE4ME on 17.05.2023.
//

import Foundation;
import plist;


enum PlistFormat: CaseIterable {
    case bin;
    case xml;
    case json;
    case openStep;
}

extension PlistFormat {
    init?(description: String) {
        if let format = PlistFormat.allCases.first(where: {$0.description == description;} ) {
            self = format;
        } else {
            return nil;
        }
    }
}

extension PlistFormat: CustomStringConvertible {
    var description: String {
        switch self {
        case .bin:
            return "Binary";
        case .json:
            return "JSON";
        case .xml:
            return "XML";
        case .openStep:
            return "OpenStep";
        }
    }
}


struct PlistOption: OptionSet {
    
    static let debug = PlistOption(rawValue: 1 << 0);
    static let compact = PlistOption(rawValue: 1 << 1);
    static let sort = PlistOption(rawValue: 1 << 2);
    
    let rawValue: Int;
    
}


struct PlistError: Error {
    
    static let success = PlistError(rawValue: PLIST_ERR_SUCCESS);
    static let unknown = PlistError(rawValue: PLIST_ERR_UNKNOWN);
    static let noMemory = PlistError(rawValue: PLIST_ERR_NO_MEM);
    static let parse = PlistError(rawValue: PLIST_ERR_PARSE);
    static let format = PlistError(rawValue: PLIST_ERR_FORMAT);
    static let invalidArguments = PlistError(rawValue: PLIST_ERR_INVALID_ARG);
    static let inputOutput = PlistError(rawValue: PLIST_ERR_IO);
    
    let rawValue: plist_err_t;

}

extension PlistError: CustomStringConvertible {
    var description: String {
        switch self {
        case .success:
            return "Operation successful";
        case .invalidArguments:
            return "One or more of the parameters are invalid";
        case .format:
            return "The plist contains nodes not compatible with the output format";
        case .parse:
            return "Parsing of the input format failed";
        case .noMemory:
            return "Not enough memory to handle the operation";
        case .inputOutput:
            return "I/O error";
        default:
            return "An unspecified error occurred";
        }
    }
}

extension PlistError: LocalizedError {
    var errorDescription: String? {
        self.description;
    }
}

extension PlistError: Equatable {
    static func == (lhs: PlistError, rhs: PlistError) -> Bool {
        lhs.rawValue == rhs.rawValue;
    }
}


class ConvertOperation: Operation {
    
    private static let convertQueue = OperationQueue();
    
    let inputUrl: URL;
    let outputUrl: URL;
    let options: PlistOption;
    let outputFormat: PlistFormat;
    private(set) var error: Error;
    
    init(inputUrl: URL, outputUrl: URL, outputFormat: PlistFormat = .xml, options: PlistOption = []) {
        self.inputUrl = inputUrl;
        self.outputUrl = outputUrl;
        self.outputFormat = outputFormat;
        self.options = options;
        self.error = PlistError.unknown;
    }
    
    func convert() {
        ConvertOperation.convertQueue.addOperation(self);
    }
    
    override func main() {
        do {
            #if DEBUG
            if (self.options.contains(.debug)) {
                plist_set_debug(1);
            }
            #endif
            let data = try Data(contentsOf: self.inputUrl);
            let plist = try data.withUnsafeBytes { pointer -> plist_t in
                var plist: plist_t?;
                guard let bytes = pointer.baseAddress?.bindMemory(to: CChar.self, capacity: pointer.count) else {
                    throw PlistError.unknown;
                }
                let error = plist_from_memory(bytes, UInt32(pointer.count), &plist, nil);
                guard error == PLIST_ERR_SUCCESS else {
                    throw PlistError(rawValue: error);
                }
                guard plist != nil else {
                    throw PlistError.noMemory;
                }
                return plist!;
            }
            if self.options.contains(.sort) {
                plist_sort(plist);
            }
            var size: UInt32 = 0;
            var output: UnsafeMutablePointer<CChar>?;
            let error: plist_err_t;
            switch self.outputFormat {
            case .bin:
                error = plist_to_bin(plist, &output, &size);
            case .xml:
                error = plist_to_xml(plist, &output, &size);
            case .json:
                error = plist_to_json(plist, &output, &size, self.options.contains(.compact) ? 0 : 1);
            case .openStep:
                error = plist_to_openstep(plist, &output, &size, self.options.contains(.compact) ? 0 : 1);
            }
            guard error == PLIST_ERR_SUCCESS else {
                throw PlistError(rawValue: error);
            }
            guard let bytes = output else {
                throw PlistError.unknown;
            }
            let deallocator: Data.Deallocator = .custom { pointer, size in
                plist_mem_free(pointer);
            }
            let output_data = Data(bytesNoCopy: bytes, count: Int(size), deallocator: deallocator);
            try output_data.write(to: self.outputUrl);
            self.error = PlistError.success;
        }
        catch {
            self.error = error;
            print(error);
        }
    }
    
}
