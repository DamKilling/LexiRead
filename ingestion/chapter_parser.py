import re
from typing import List, Tuple
from ingestion.text_cleaner import clean_text_block

def parse_chapters(content: str) -> List[Tuple[str, str]]:
    """
    Splits cleaned text into chapters based on CHAPTER or SCENE markers.
    Returns a list of (chapter_title, chapter_content) tuples.
    """
    # Regex to find CHAPTER, SCENE, BOOK, PART, ADVENTURE followed by numbers/numerals
    raw_chunks = re.split(r'(?im)(^(?:CHAPTER|SCENE|BOOK|PART|ADVENTURE|STORY|ACT)\s+[A-ZIVX0-9]+\.*.*)', content)
    
    raw_chapters = []
    
    # If no chapters found, treat the whole book as one chapter
    if len(raw_chunks) <= 1:
        return [("Chapter 1", clean_text_block(content.strip()))]
        
    # The first chunk is usually prologue or front matter before Chapter 1
    if raw_chunks[0].strip():
        raw_chapters.append(("Prologue / Intro", clean_text_block(raw_chunks[0].strip())))
        
    for i in range(1, len(raw_chunks), 2):
        scene_title = raw_chunks[i].strip()
        scene_content = raw_chunks[i+1] if i+1 < len(raw_chunks) else ""
        
        # Combine title and cleaned content
        clean_content = scene_title + "\n\n" + clean_text_block(scene_content.strip())
        raw_chapters.append((scene_title, clean_content))
        
    return raw_chapters
