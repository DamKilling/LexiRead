import os
import re
from supabase import create_client, Client

SUPABASE_URL = "https://njxzcpgnxbcjgxinzafa.supabase.co"
SUPABASE_KEY = "***REMOVED_SECRET***"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def clean_text_block(text_block):
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

def import_book_from_txt(txt_path, title, author, cover_url, difficulty):
    print(f"Importing {title}...")
    with open(txt_path, 'r', encoding='utf-8') as file:
        content = file.read()
        
    book_data = {
        "title": title,
        "author": author,
        "cover_url": cover_url,
        "difficulty_level": difficulty,
        "description": f"A classic book: {title}",
        "total_chapters": 0
    }
    
    book_res = supabase.table("books").insert(book_data).execute()
    book_id = book_res.data[0]['id']
    
    raw_chunks = re.split(r'(?im)(^(?:CHAPTER|SCENE)\s+[A-ZIVX0-9]+\.*.*)', content)
    
    raw_chapters = []
    if len(raw_chunks) > 0:
        raw_chapters.append(("Prologue / Intro", raw_chunks[0]))
        for i in range(1, len(raw_chunks), 2):
            scene_title = raw_chunks[i].strip()
            scene_content = raw_chunks[i+1] if i+1 < len(raw_chunks) else ""
            raw_chapters.append((scene_title, scene_title + "\n\n" + scene_content.strip()))

    chapter_number = 1
    inserted_chapters = 0

    for ch_title, text_block in raw_chapters:
        text_block = text_block.strip()
        if not text_block or len(text_block) < 200:
            continue
            
        if "*** END OF THE PROJECT GUTENBERG" in text_block:
            text_block = text_block.split("*** END OF THE PROJECT GUTENBERG")[0].strip()

        # Clean the text format to remove hard wraps
        clean_content = clean_text_block(text_block)
        word_count = len(clean_content.split())

        chapter_data = {
            "book_id": book_id,
            "chapter_number": chapter_number,
            "title": ch_title[:50],
            "content": clean_content,
            "word_count": word_count
        }

        supabase.table("chapters").insert(chapter_data).execute()
        chapter_number += 1
        inserted_chapters += 1

    supabase.table("books").update({"total_chapters": inserted_chapters}).eq("id", book_id).execute()
    print(f"Finished importing {title} with {inserted_chapters} chapters.\n")

if __name__ == "__main__":
    # 1. Delete all existing books to avoid duplicates
    print("Deleting existing books...")
    try:
        # We need to fetch all books first because delete without eq might fail on some setups
        books = supabase.table("books").select("id").execute()
        for b in books.data:
            supabase.table("books").delete().eq("id", b["id"]).execute()
            print(f"Deleted book {b['id']}")
    except Exception as e:
        print(f"Error deleting: {e}")

    # 2. Import Romeo and Juliet
    import_book_from_txt(
        txt_path="pg1513.txt",
        title="Romeo and Juliet",
        author="William Shakespeare",
        cover_url="https://njxzcpgnxbcjgxinzafa.supabase.co/storage/v1/object/public/covers/pg1513.cover.medium.jpg",
        difficulty="C1"
    )

    # 3. Import Wuthering Heights
    import_book_from_txt(
        txt_path="Wuthering.txt",
        title="Wuthering Heights",
        author="Emily Brontë",
        cover_url="https://njxzcpgnxbcjgxinzafa.supabase.co/storage/v1/object/public/covers/pg768.cover.medium.jpg",
        difficulty="C1"
    )
