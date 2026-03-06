import os
import glob

replacements = {
    "LexiRead": "LexiRead",
    "lexiread": "lexiread",
    "lexiread": "lexiread",
    "LexiRead": "LexiRead"
}

def replace_in_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = content
        for old, new in replacements.items():
            new_content = new_content.replace(old, new)
            
        if content != new_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Updated {filepath}")
    except Exception as e:
        pass

def main():
    target_exts = ['.dart', '.yaml', '.xml', '.plist', '.pbxproj', '.md', '.json', '.html', '.rc', '.cpp', '.py']
    for root, dirs, files in os.walk('D:/lexiread'):
        if '.git' in root or '.dart_tool' in root or 'build' in root:
            continue
        for file in files:
            if any(file.endswith(ext) for ext in target_exts):
                replace_in_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
