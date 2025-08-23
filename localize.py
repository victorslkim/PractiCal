#!/usr/bin/env python3
"""
PractiCal Localization Automation Script
Automates translation of Localizable.strings files using AI translation services
"""

import os
import re
import json
import time
import shutil
from datetime import datetime
from pathlib import Path
import requests
from typing import Dict, List, Optional

class LocalizationAutomator:
    def __init__(self, api_key: str = "", model: str = "gpt-4"):
        self.api_key = api_key
        self.model = model
        self.base_path = Path("PractiCal/Localization")
        self.english_file = self.base_path / "en.lproj" / "Localizable.strings"
        
        # Target languages (ISO 639-1 codes)
        self.languages = [
            "ja", "ko", "es", "fr", "de", "zh", "ru", "ar", "hi", "pt",
            "it", "nl", "sv", "da", "no", "fi", "pl", "tr", "uk", "vi"
        ]
        
        # Language names for better prompts
        self.language_names = {
            "ja": "Japanese", "ko": "Korean", "es": "Spanish", "fr": "French",
            "de": "German", "zh": "Chinese (Simplified)", "ru": "Russian",
            "ar": "Arabic", "hi": "Hindi", "pt": "Portuguese", "it": "Italian",
            "nl": "Dutch", "sv": "Swedish", "da": "Danish", "no": "Norwegian",
            "fi": "Finnish", "pl": "Polish", "tr": "Turkish", "uk": "Ukrainian",
            "vi": "Vietnamese"
        }

    def extract_strings(self, file_path: Path) -> Dict[str, str]:
        """Extract key-value pairs from .strings file"""
        strings = {}
        if not file_path.exists():
            return strings
            
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Match "key" = "value"; pattern
        pattern = r'"([^"]+)"\s*=\s*"([^"]+)";'
        matches = re.findall(pattern, content)
        
        for key, value in matches:
            strings[key] = value
            
        return strings

    def translate_text(self, text: str, target_lang: str) -> str:
        """Translate text using OpenAI API"""
        if not self.api_key:
            return f"[TRANSLATED: {text}]"
            
        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        lang_name = self.language_names.get(target_lang, target_lang)
        
        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "system",
                    "content": f"You are a professional translator. Translate the given text to {lang_name}. Return only the translation, nothing else. Maintain the same tone and context as the original. For UI elements, use appropriate terminology for that language."
                },
                {
                    "role": "user",
                    "content": f"Translate this text to {lang_name}: {text}"
                }
            ],
            "max_tokens": 150,
            "temperature": 0.3
        }
        
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            if 'choices' in result and len(result['choices']) > 0:
                translation = result['choices'][0]['message']['content'].strip()
                return translation
            else:
                print(f"❌ Translation failed for: {text}")
                return f"[TRANSLATION_ERROR: {text}]"
                
        except Exception as e:
            print(f"❌ API error for '{text}': {e}")
            return f"[API_ERROR: {text}]"

    def backup_existing(self) -> str:
        """Backup existing translation files"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = Path(f"localization_backup_{timestamp}")
        backup_dir.mkdir(exist_ok=True)
        
        print(f"📦 Creating backup in: {backup_dir}")
        
        for lang in self.languages:
            lang_file = self.base_path / f"{lang}.lproj" / "Localizable.strings"
            if lang_file.exists():
                backup_file = backup_dir / f"{lang}.strings"
                shutil.copy2(lang_file, backup_file)
                print(f"  ✓ Backed up {lang}")
                
        return str(backup_dir)

    def translate_language(self, target_lang: str, english_strings: Dict[str, str]) -> None:
        """Translate all strings for a specific language"""
        print(f"\n🌐 Translating to {target_lang} ({self.language_names.get(target_lang, target_lang)})...")
        
        # Create target directory
        target_dir = self.base_path / f"{target_lang}.lproj"
        target_dir.mkdir(parents=True, exist_ok=True)
        
        target_file = target_dir / "Localizable.strings"
        
        with open(target_file, 'w', encoding='utf-8') as f:
            f.write(f"/* Localized strings for {target_lang} */\n\n")
            
            for key, value in english_strings.items():
                if value.strip():  # Skip empty values
                    print(f"  Translating '{key}'...", end=" ")
                    translation = self.translate_text(value, target_lang)
                    print("✓")
                    
                    f.write(f'"{key}" = "{translation}";\n')
                    
                    # Rate limiting
                    time.sleep(0.5)
                else:
                    f.write(f'"{key}" = "{value}";\n')
        
        print(f"  ✅ Completed {target_lang}")

    def validate_translations(self, english_strings: Dict[str, str]) -> None:
        """Validate that all languages have the same number of keys"""
        print("\n🔍 Validating translations...")
        
        english_count = len(english_strings)
        
        for lang in self.languages:
            lang_file = self.base_path / f"{lang}.lproj" / "Localizable.strings"
            if lang_file.exists():
                lang_strings = self.extract_strings(lang_file)
                lang_count = len(lang_strings)
                
                if lang_count == english_count:
                    print(f"  ✅ {lang}: {lang_count} keys")
                else:
                    print(f"  ❌ {lang}: {lang_count}/{english_count} keys")
            else:
                print(f"  ❌ {lang}: File not found")

    def run(self) -> None:
        """Main execution function"""
        print("🌐 PractiCal Localization Automation")
        print("=" * 40)
        
        # Check if English file exists
        if not self.english_file.exists():
            print(f"❌ Error: English file not found at {self.english_file}")
            return
        
        # Check API key
        if not self.api_key:
            print("⚠️  Warning: No API key set. This will create placeholder translations.")
            response = input("Continue anyway? (y/N): ")
            if response.lower() != 'y':
                return
        
        # Extract English strings
        print("📖 Extracting English strings...")
        english_strings = self.extract_strings(self.english_file)
        print(f"  Found {len(english_strings)} strings to translate")
        
        # Backup existing translations
        backup_dir = self.backup_existing()
        
        # Translate each language
        for lang in self.languages:
            self.translate_language(lang, english_strings)
        
        # Validate translations
        self.validate_translations(english_strings)
        
        print(f"\n🎉 Localization complete!")
        print(f"📦 Backup saved to: {backup_dir}")
        print("\n📋 Next steps:")
        print("1. Review translations for accuracy")
        print("2. Test the app with different languages")
        print("3. Update any hardcoded strings that weren't localized")
        print("4. Consider using professional translation services for final release")

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Automate PractiCal localization")
    parser.add_argument("--api-key", help="OpenAI API key")
    parser.add_argument("--model", default="gpt-4", help="OpenAI model to use")
    parser.add_argument("--languages", nargs="+", help="Specific languages to translate")
    
    args = parser.parse_args()
    
    # Get API key from environment if not provided
    api_key = args.api_key or os.getenv("OPENAI_API_KEY", "")
    
    automator = LocalizationAutomator(api_key=api_key, model=args.model)
    
    if args.languages:
        automator.languages = args.languages
    
    automator.run()

if __name__ == "__main__":
    main()
