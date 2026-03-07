import re

def clean_gutenberg_text(raw_text: str) -> str:
    """
    Strips Gutenberg boilerplate.
    Note: We no longer call clean_text_block here to preserve single newlines
    so that Table of Contents isn't merged into one giant line before chapter splitting.
    """
    # 1. Remove Gutenberg start boilerplate
    start_match = re.search(r'\*\*\*\s*START OF (?:THE|THIS) PROJECT GUTENBERG.*?\*\*\*', raw_text, re.IGNORECASE)
    if start_match:
        raw_text = raw_text[start_match.end():]
        
    # 2. Remove Gutenberg end boilerplate
    end_match = re.search(r'\*\*\*\s*END OF (?:THE|THIS) PROJECT GUTENBERG.*?\*\*\*', raw_text, re.IGNORECASE)
    if end_match:
        raw_text = raw_text[:end_match.start()]
        
    return raw_text.strip()

def clean_text_block(text_block: str) -> str:
    """
    Normalizes hard wraps and cleans paragraphs.
    Reuses existing logic from clean_and_import.py.
    """
    # Normalize newlines
    text_block = text_block.replace('\r\n', '\n')
    
    # Split by double newline to get actual paragraphs
    paragraphs = text_block.split('\n\n')
    cleaned_paragraphs = []
    
    for p in paragraphs:
        p = p.strip()
        if p:
            # Replace single newlines inside a paragraph with a space
            p = re.sub(r'(?<!\n)\n(?!\n)', ' ', p)
            # Remove multiple spaces
            p = re.sub(r' +', ' ', p)
            cleaned_paragraphs.append(p)
            
    # Join paragraphs with a single newline so Flutter's split('\n') works perfectly
    return '\n'.join(cleaned_paragraphs)
