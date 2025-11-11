#!/usr/bin/env python3
"""
Session Validator for Terminal Debugging
Analyzes captured sessions to identify common terminal issues
"""

import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

class SessionValidator:
    def __init__(self, session_dir: str):
        self.session_dir = Path(session_dir)
        self.issues = []
        self.warnings = []
        self.info = []
        
    def validate(self) -> Dict:
        """Run all validation checks"""
        print(f"Validating session: {self.session_dir.name}")
        print("=" * 60)
        
        self.check_metadata()
        self.check_environment()
        self.check_locale()
        self.check_typescript_issues()
        self.check_diagnostics()
        
        return {
            "session": self.session_dir.name,
            "issues": self.issues,
            "warnings": self.warnings,
            "info": self.info,
        }
    
    def check_metadata(self):
        """Check session metadata"""
        metadata_file = self.session_dir / "metadata.json"
        if not metadata_file.exists():
            self.issues.append("Missing metadata.json file")
            return
        
        try:
            with open(metadata_file) as f:
                metadata = json.load(f)
            
            self.info.append(f"Session: {metadata.get('name', 'unknown')}")
            self.info.append(f"Description: {metadata.get('description', 'N/A')}")
            self.info.append(f"Created: {metadata.get('created', 'unknown')}")
            
            if metadata.get('minimal_config'):
                self.info.append("Using minimal configuration")
            
            if metadata.get('tmux_isolated'):
                self.info.append("Running in isolated tmux session")
                
        except json.JSONDecodeError:
            self.issues.append("Invalid metadata.json format")
    
    def check_environment(self):
        """Check environment variables"""
        env_file = self.session_dir / "environment.txt"
        if not env_file.exists():
            self.warnings.append("Missing environment.txt file")
            return
        
        with open(env_file) as f:
            env_content = f.read()
        
        # Check for common environment issues
        if 'LANG=' not in env_content or 'UTF-8' not in env_content:
            self.issues.append("LANG not set to UTF-8 locale")
        
        if 'LC_ALL=' not in env_content or 'UTF-8' not in env_content.split('LC_ALL=')[1].split('\n')[0]:
            self.warnings.append("LC_ALL not set to UTF-8 locale")
        
        # Check TERM
        term_match = re.search(r'TERM=(.+)', env_content)
        if term_match:
            term_value = term_match.group(1)
            if '256color' not in term_value:
                self.warnings.append(f"TERM={term_value} - consider using 256color variant")
        else:
            self.issues.append("TERM variable not set")
    
    def check_locale(self):
        """Check locale settings"""
        locale_file = self.session_dir / "locale.txt"
        if not locale_file.exists():
            self.warnings.append("Missing locale.txt file")
            return
        
        with open(locale_file) as f:
            locale_content = f.read()
        
        # Check if all locale vars are UTF-8
        locale_lines = locale_content.strip().split('\n')
        non_utf8 = []
        
        for line in locale_lines:
            if '=' in line and 'UTF-8' not in line and line.strip() and not line.endswith('='):
                var_name = line.split('=')[0]
                non_utf8.append(var_name)
        
        if non_utf8:
            self.warnings.append(f"Non-UTF-8 locale variables: {', '.join(non_utf8)}")
    
    def check_typescript_issues(self):
        """Analyze typescript file for common terminal issues"""
        typescript_file = self.session_dir / "typescript"
        if not typescript_file.exists():
            self.issues.append("Missing typescript file - session may not have been recorded")
            return
        
        try:
            # Read as bytes to handle binary data
            with open(typescript_file, 'rb') as f:
                content = f.read()
            
            # Try to decode as UTF-8
            try:
                text = content.decode('utf-8')
            except UnicodeDecodeError as e:
                self.issues.append(f"UTF-8 decode error in typescript at position {e.start}")
                # Try to decode with replacement
                text = content.decode('utf-8', errors='replace')
            
            # Check for replacement characters (indicates encoding issues)
            replacement_count = text.count('\ufffd')
            if replacement_count > 0:
                self.issues.append(f"Found {replacement_count} replacement characters (�) - encoding issue")
            
            # Check for control sequences that might indicate rendering issues
            if '\x1b[?1049h' in text or '\x1b[?1049l' in text:
                self.info.append("Alternate screen buffer used (normal for TUI apps)")
            
            # Check for box drawing characters
            box_chars = re.findall(r'[┌┐└┘├┤┬┴┼─│╔╗╚╝╠╣╦╩╬═║]', text)
            if box_chars:
                self.info.append(f"Found {len(box_chars)} box drawing characters")
            
            # Check for emoji
            emoji_pattern = re.compile(
                "["
                "\U0001F600-\U0001F64F"  # emoticons
                "\U0001F300-\U0001F5FF"  # symbols & pictographs
                "\U0001F680-\U0001F6FF"  # transport & map symbols
                "\U0001F1E0-\U0001F1FF"  # flags
                "\U00002702-\U000027B0"
                "\U000024C2-\U0001F251"
                "]+",
                flags=re.UNICODE
            )
            emoji_matches = emoji_pattern.findall(text)
            if emoji_matches:
                self.info.append(f"Found {len(emoji_matches)} emoji sequences")
            
            # Check for CJK characters
            cjk_pattern = re.compile(r'[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff\uac00-\ud7af]+')
            cjk_matches = cjk_pattern.findall(text)
            if cjk_matches:
                self.info.append(f"Found {len(cjk_matches)} CJK character sequences")
            
            # Check for backspace sequences (might indicate backspace issues)
            backspace_count = text.count('\x08') + text.count('\x7f')
            if backspace_count > 10:
                self.info.append(f"Found {backspace_count} backspace characters")
            
        except Exception as e:
            self.warnings.append(f"Error analyzing typescript: {str(e)}")
    
    def check_diagnostics(self):
        """Check diagnostics output if available"""
        diag_file = self.session_dir / "diagnostics.txt"
        if not diag_file.exists():
            self.info.append("No diagnostics file available")
            return
        
        with open(diag_file) as f:
            diag_content = f.read()
        
        # Parse diagnostics for issues
        if 'UTF-8 in environment: No' in diag_content:
            self.issues.append("Diagnostics show UTF-8 not in environment")
        
        if 'Terminfo entry exists: No' in diag_content:
            self.issues.append("Terminal type not found in terminfo database")
        
        # Check color support
        color_match = re.search(r'colors\s+.*:\s*(\d+)', diag_content)
        if color_match:
            colors = int(color_match.group(1))
            if colors < 256:
                self.warnings.append(f"Terminal only supports {colors} colors (recommend 256+)")
    
    def print_report(self):
        """Print validation report"""
        print()
        
        if self.info:
            print("\n📋 Information:")
            for item in self.info:
                print(f"   ℹ️  {item}")
        
        if self.warnings:
            print("\n⚠️  Warnings:")
            for item in self.warnings:
                print(f"   ⚠️  {item}")
        
        if self.issues:
            print("\n❌ Issues:")
            for item in self.issues:
                print(f"   ❌ {item}")
        
        print()
        
        # Overall assessment
        if not self.issues:
            print("✅ No critical issues found!")
        else:
            print(f"❌ Found {len(self.issues)} issue(s) that need attention")
        
        if self.warnings:
            print(f"⚠️  Found {len(self.warnings)} warning(s)")
        
        print()

def main():
    if len(sys.argv) < 2:
        print("Usage: session_validator.py <session_directory>")
        print()
        print("Validates a recorded terminal session and identifies issues")
        sys.exit(1)
    
    session_dir = sys.argv[1]
    
    if not os.path.isdir(session_dir):
        print(f"Error: '{session_dir}' is not a directory")
        sys.exit(1)
    
    validator = SessionValidator(session_dir)
    result = validator.validate()
    validator.print_report()
    
    # Exit with error code if issues found
    sys.exit(1 if result['issues'] else 0)

if __name__ == '__main__':
    main()
