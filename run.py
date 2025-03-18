#!/usr/bin/env python3
"""
Flutter Localization Helper for easy_localization

This script helps with replacing hardcoded strings in Flutter projects with
localization keys using easy_localization package.

Usage:
    python flutter_localization.py --json assets/languages/en.json --src lib

The script will:
1. Load the localization JSON file
2. Scan Dart files for text strings
3. Match strings with localization keys
4. Generate replacement suggestions using .tr() syntax
5. Optionally apply changes after confirmation
"""

import os
import re
import json
import argparse
from collections import defaultdict
import difflib

def flatten_json(json_obj, prefix='', result=None):
    """Flatten nested JSON object to dot-notation keys."""
    if result is None:
        result = {}
    
    for key, value in json_obj.items():
        new_key = f"{prefix}{key}" if prefix else key
        
        if isinstance(value, dict):
            flatten_json(value, f"{new_key}.", result)
        else:
            result[new_key] = value
    
    return result

def find_dart_files(directory):
    """Find all Dart files in a directory and its subdirectories."""
    dart_files = []
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    return dart_files

def extract_text_strings(dart_file):
    """Extract potential text strings from a Dart file."""
    with open(dart_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to match strings in various Flutter widgets
    patterns = [
        r'Text\(\s*["\'](.+?)["\']\s*(?:,|\))',  # Text('string')
        r'label:\s*["\'](.+?)["\']\s*(?:,|\))',  # label: 'string'
        r'hint(?:Text)?:\s*["\'](.+?)["\']\s*(?:,|\))',  # hintText: 'string'
        r'title:\s*["\'](.+?)["\']\s*(?:,|\))',  # title: 'string'
        r'subtitle:\s*["\'](.+?)["\']\s*(?:,|\))',  # subtitle: 'string'
        r'tooltip:\s*["\'](.+?)["\']\s*(?:,|\))',  # tooltip: 'string'
        r'message:\s*["\'](.+?)["\']\s*(?:,|\))',  # message: 'string'
        r'AppBar\(\s*title:\s*Text\(\s*["\'](.+?)["\']\s*\)',  # AppBar(title: Text('string'))
    ]
    
    text_strings = []
    line_numbers = []
    contexts = []
    
    for pattern in patterns:
        for match in re.finditer(pattern, content):
            text = match.group(1)
            # Skip if it's just a variable placeholder or already localized
            if text.startswith('$') or text.startswith('{') or len(text) < 2 or '.tr()' in text:
                continue
                
            # Get line number
            line_num = content[:match.start()].count('\n') + 1
            
            # Get context (surrounding code)
            lines = content.split('\n')
            context_start = max(0, line_num - 2)
            context_end = min(len(lines), line_num + 1)
            context = '\n'.join(lines[context_start:context_end])
            
            text_strings.append(text)
            line_numbers.append(line_num)
            contexts.append(context)
    
    return text_strings, line_numbers, contexts, dart_file

def find_best_match(string, flat_json):
    """Find the best matching key for a string in the flattened JSON."""
    for key, value in flat_json.items():
        if isinstance(value, str) and value.lower() == string.lower():
            return key
    
    # Try to find close matches
    best_ratio = 0
    best_key = None
    
    for key, value in flat_json.items():
        if isinstance(value, str):
            ratio = difflib.SequenceMatcher(None, string.lower(), value.lower()).ratio()
            if ratio > 0.9 and ratio > best_ratio:  # 90% similarity threshold
                best_ratio = ratio
                best_key = key
    
    return best_key

def generate_localized_code(original_line, string, key):
    """Generate localized code using easy_localization's .tr() syntax."""
    # For easy_localization, we replace "string" with "key".tr()
    quote_type = "'" if f"'{string}'" in original_line else '"'
    if 'Text(' in original_line:
        localized_version = original_line.replace(
            f'{quote_type}{string}{quote_type}',
            f'{quote_type}{key}{quote_type}.tr()'
        )
    else:
        # For named parameters (label:, hintText:, etc.)
        localized_version = original_line.replace(
            f'{quote_type}{string}{quote_type}',
            f'{quote_type}{key}{quote_type}.tr()'
        )
    
    return localized_version

def process_dart_files(dart_files, flat_json):
    """Process all Dart files and suggest replacements."""
    replacements = []
    
    for dart_file in dart_files:
        strings, line_numbers, contexts, file_path = extract_text_strings(dart_file)
        
        for string, line_number, context in zip(strings, line_numbers, contexts):
            key = find_best_match(string, flat_json)
            if key:
                # Get the original line
                with open(dart_file, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    original_line = lines[line_number - 1]
                
                # Generate localized version
                localized_line = generate_localized_code(original_line, string, key)
                
                replacements.append({
                    'file': dart_file,
                    'line': line_number,
                    'original': original_line.strip(),
                    'string': string,
                    'key': key,
                    'replacement': localized_line.strip(),
                    'context': context
                })
    
    return replacements

def interactive_replace(replacements):
    """Interactively apply replacements with user confirmation."""
    # Group by file for better organization
    by_file = defaultdict(list)
    for rep in replacements:
        by_file[rep['file']].append(rep)
    
    files_modified = []
    
    for file_path, file_replacements in by_file.items():
        print(f"\n\nProcessing file: {file_path}")
        print(f"Found {len(file_replacements)} potential replacements")
        
        # Read the file content
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        modified = False
        
        # Process each replacement
        for rep in sorted(file_replacements, key=lambda x: x['line'], reverse=True):
            print("\n" + "="*80)
            print(f"Line {rep['line']}: \n{rep['context']}")
            print("-"*80)
            print(f"String: '{rep['string']}'")
            print(f"Key: {rep['key']}")
            print(f"Original: {rep['original']}")
            print(f"Replacement: {rep['replacement']}")
            
            choice = input("Apply this replacement? (y/n/a - yes/no/all): ").strip().lower()
            
            if choice == 'y' or choice == 'a':
                # Apply the replacement
                lines[rep['line'] - 1] = lines[rep['line'] - 1].replace(rep['original'], rep['replacement'])
                modified = True
                
                if choice == 'a':
                    # Apply all remaining replacements for this file without asking
                    for remaining in file_replacements:
                        if remaining != rep:
                            lines[remaining['line'] - 1] = lines[remaining['line'] - 1].replace(
                                remaining['original'], remaining['replacement']
                            )
                    break
        
        # Write changes back to the file if modified
        if modified:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
            files_modified.append(file_path)
            print(f"Modified file: {file_path}")
    
    print(f"\nCompleted! Modified {len(files_modified)} files.")

def export_replacement_report(replacements, output_file):
    """Export a CSV report of all potential replacements."""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("File,Line,String,Key,Original,Replacement\n")
        for rep in replacements:
            f.write(f'"{rep["file"]}",{rep["line"]},"{rep["string"]}",{rep["key"]},"{rep["original"]}","{rep["replacement"]}"\n')
    
    print(f"Exported report to {output_file}")

def main():
    parser = argparse.ArgumentParser(description="Flutter Localization Helper for easy_localization")
    parser.add_argument('--json', required=True, help="Path to localization JSON file")
    parser.add_argument('--src', required=True, help="Path to Flutter project's lib directory")
    parser.add_argument('--interactive', action='store_true', help="Interactive mode to approve changes")
    parser.add_argument('--report', help="Path to export replacement report CSV")
    
    args = parser.parse_args()
    
    # Load and flatten the localization JSON
    with open(args.json, 'r', encoding='utf-8') as f:
        json_data = json.load(f)
    
    flat_json = flatten_json(json_data)
    print(f"Loaded {len(flat_json)} localization strings")
    
    # Find all Dart files
    dart_files = find_dart_files(args.src)
    print(f"Found {len(dart_files)} Dart files")
    
    # Process Dart files and get replacement suggestions
    replacements = process_dart_files(dart_files, flat_json)
    print(f"Found {len(replacements)} potential string replacements")
    
    # Export report if specified
    if args.report:
        export_replacement_report(replacements, args.report)
    
    # Interactive replacement if specified
    if args.interactive:
        interactive_replace(replacements)
    elif not args.report:
        print("No action taken. Use --interactive to apply changes or --report to export a report.")

if __name__ == "__main__":
    main()