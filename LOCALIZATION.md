# PractiCal Localization Automation

This document explains how to automate the localization process for PractiCal, so you don't have to manually translate every string during development.

## 🚀 Quick Start

### Option 1: Python Script (Recommended)

```bash
# Install required dependencies
pip install requests

# Set your OpenAI API key
export OPENAI_API_KEY="your-api-key-here"

# Run the automation script
python3 localize.py

# Or specify specific languages
python3 localize.py --languages ja ko es fr
```

### Option 2: Bash Script

```bash
# Edit the script to add your API key
nano localize.sh

# Make it executable and run
chmod +x localize.sh
./localize.sh
```

## 📋 How It Works

1. **Extracts** all strings from `PractiCal/Localization/en.lproj/Localizable.strings`
2. **Backs up** existing translations to avoid losing work
3. **Translates** each string using AI (OpenAI GPT-4)
4. **Validates** that all languages have the same number of keys
5. **Creates** properly formatted `.strings` files for each language

## 🔧 Configuration

### Supported Languages

The scripts support these languages by default:
- Japanese (ja)
- Korean (ko)
- Spanish (es)
- French (fr)
- German (de)
- Chinese Simplified (zh)
- Russian (ru)
- Arabic (ar)
- Hindi (hi)
- Portuguese (pt)
- Italian (it)
- Dutch (nl)
- Swedish (sv)
- Danish (da)
- Norwegian (no)
- Finnish (fi)
- Polish (pl)
- Turkish (tr)
- Ukrainian (uk)
- Vietnamese (vi)

### API Configuration

**OpenAI API Key**: Required for actual translations
- Get one at: https://platform.openai.com/api-keys
- Set as environment variable: `export OPENAI_API_KEY="your-key"`
- Or pass as argument: `--api-key "your-key"`

**Model Selection**:
- `gpt-4` (default) - Better quality, higher cost
- `gpt-3.5-turbo` - Faster, lower cost

## 💰 Cost Estimation

Using GPT-4 for ~100 strings across 20 languages:
- **Cost**: ~$2-5 USD
- **Time**: ~10-15 minutes
- **Quality**: Good for initial translations

## 🎯 Development Workflow

### During Development
1. **Add new strings** to `en.lproj/Localizable.strings` only
2. **Use English** in your code with `L("key")` function
3. **Focus on features** - don't worry about translations yet

### Before Release
1. **Run automation**: `python3 localize.py`
2. **Review translations** for accuracy and context
3. **Test the app** with different languages
4. **Fix any issues** found during testing
5. **Consider professional review** for major languages

## 🔍 Quality Assurance

### What the Scripts Do Well
- ✅ Maintains consistent terminology
- ✅ Preserves UI context
- ✅ Handles placeholders and formatting
- ✅ Creates proper `.strings` file format

### What to Review Manually
- 🔍 **Cultural context** - some phrases may need localization
- 🔍 **Technical terms** - ensure consistency with platform conventions
- 🔍 **Length issues** - some languages may be longer/shorter
- 🔍 **Formality levels** - adjust tone for target audience

## 🛠️ Advanced Usage

### Custom Language Set
```bash
python3 localize.py --languages ja ko es fr de
```

### Different Model
```bash
python3 localize.py --model gpt-3.5-turbo
```

### Environment Variable
```bash
export OPENAI_API_KEY="your-key"
python3 localize.py
```

## 📁 File Structure

```
PractiCal/
├── Localization/
│   ├── en.lproj/
│   │   └── Localizable.strings    # Source of truth
│   ├── ja.lproj/
│   │   └── Localizable.strings    # Generated
│   ├── ko.lproj/
│   │   └── Localizable.strings    # Generated
│   └── ... (other languages)
├── localize.py                    # Python automation script
├── localize.sh                    # Bash automation script
└── LOCALIZATION.md               # This file
```

## 🚨 Important Notes

1. **Backup**: Scripts automatically backup existing translations
2. **Rate Limiting**: Built-in delays to avoid API rate limits
3. **Error Handling**: Failed translations are marked for manual review
4. **Cost Control**: Scripts show progress and estimated costs

## 🔄 Updating Translations

When you add new strings:

1. **Add to English file** only
2. **Run automation** to translate new strings
3. **Review** new translations
4. **Test** the app

The scripts will preserve existing translations and only translate new strings.

## 🆘 Troubleshooting

### Common Issues

**"API key not found"**
- Set environment variable: `export OPENAI_API_KEY="your-key"`
- Or pass as argument: `--api-key "your-key"`

**"Translation failed"**
- Check internet connection
- Verify API key is valid
- Check API usage limits

**"File not found"**
- Ensure you're running from the project root
- Check that `en.lproj/Localizable.strings` exists

### Getting Help

- Check the script output for error messages
- Verify your API key and internet connection
- Review the backup files if something goes wrong

## 🎉 Benefits

- **Save time**: No more manual translation during development
- **Consistency**: AI maintains consistent terminology
- **Quality**: Good initial translations that can be refined
- **Scalability**: Easy to add new languages
- **Cost-effective**: Much cheaper than professional translation services

This automation allows you to focus on building features while ensuring your app is ready for international users when you're ready to release!
