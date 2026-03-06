import os
import sys
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import uvicorn

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
from ingestion.gutendex_client import GutendexClient
from ingestion.downloader import download_text
from ingestion.text_cleaner import clean_gutenberg_text
from ingestion.chapter_parser import parse_chapters
from ingestion.supabase_importer import SupabaseImporter
from ingestion.cover_handler import CoverHandler

load_dotenv()

app = FastAPI(title="LexiRead API")

# Add CORS middleware for Flutter web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

supa_url = os.getenv("SUPABASE_URL")
supa_key = os.getenv("SUPABASE_KEY")

gutendex = GutendexClient()
importer = SupabaseImporter(supa_url, supa_key) if supa_url and supa_key else None
cover_handler = CoverHandler(importer.client) if importer else None

class SearchResponse(BaseModel):
    id: str
    title: str
    author: str
    cover_url: Optional[str] = None
    source: str
    is_imported: bool
    text_url: Optional[str] = None
    subjects: List[str] = []

class ImportRequest(BaseModel):
    source: str
    external_id: str
    title: str
    author: str
    cover_url: Optional[str] = None
    text_url: str
    subjects: List[str] = []

@app.get("/search/external", response_model=List[SearchResponse])
def search_external(q: str, limit: int = 10):
    # Fetch more from Gutendex to allow local sorting
    fetch_limit = max(30, limit * 3)
    raw_books = gutendex.search_books(query=q, language='en', limit=fetch_limit)
    
    # Custom sort: Prioritize Title matches over Author matches
    q_lower = q.lower()
    
    def sort_key(b):
        title = b.get('title', '').lower()
        author = ''
        if b.get('authors'):
            author = b['authors'][0].get('name', '').lower()
            
        if q_lower == title:
            return 0  # Exact title match
        elif title.startswith(q_lower):
            return 1  # Title starts with query
        elif q_lower in title:
            return 2  # Title contains query
        elif q_lower in author:
            return 3  # Author contains query
        else:
            return 4  # No obvious match (Gutendex semantic match)
            
    raw_books.sort(key=sort_key)
    
    # Apply original limit after sorting
    books = raw_books[:limit]
    
    results = []
    for b in books:
        authors = b.get('authors', [])
        author_name = authors[0]['name'] if authors else 'Unknown'
        external_id = str(b.get('id', ''))
        
        is_imported = False
        if importer:
            is_imported = importer.book_exists(
                title=b.get('title'), 
                author=author_name, 
                source="gutendex", 
                external_id=external_id
            )
            
        results.append(SearchResponse(
            id=external_id,
            title=b.get('title', 'Unknown Title'),
            author=author_name,
            cover_url=b.get('cover_url'),
            source="gutendex",
            is_imported=is_imported,
            text_url=b.get('text_url'),
            subjects=b.get('subjects', [])
        ))
    return results

@app.post("/import")
def import_book(req: ImportRequest):
    if not importer:
        raise HTTPException(status_code=500, detail="Database not configured")
        
    if importer.book_exists(title=req.title, author=req.author, source=req.source, external_id=req.external_id):
        res = importer.client.table("books").select("id").eq("source", req.source).eq("external_id", req.external_id).execute()
        if res.data:
            return {"status": "success", "message": "Already imported", "book_id": res.data[0]['id']}
            
    try:
        raw_text = download_text(req.text_url)
        clean_text = clean_gutenberg_text(raw_text)
        chapters = parse_chapters(clean_text)
        
        final_cover_url = req.cover_url
        final_cover_source = None
        if cover_handler:
            final_cover_url, final_cover_source = cover_handler.process_cover(req.title, req.author, req.cover_url)
            
        book_data = {
            "title": req.title,
            "author": req.author,
            "cover_url": final_cover_url,
            "difficulty_level": "C1",
            "description": ", ".join(req.subjects[:3]) if req.subjects else f"A classic book: {req.title}",
            "source": req.source,
            "external_id": req.external_id
        }
        if final_cover_source:
            book_data["cover_source"] = final_cover_source
            
        success = importer.import_book(book_data, chapters)
        if success:
            res = importer.client.table("books").select("id").eq("source", req.source).eq("external_id", req.external_id).execute()
            if res.data:
                return {"status": "success", "book_id": res.data[0]['id']}
        
        raise HTTPException(status_code=500, detail="Failed to import to database")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
