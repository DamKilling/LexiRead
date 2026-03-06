# Deep Read 📚

Deep Read is a production-ready, Apple/X-inspired minimalist English Graded Reading application built with Flutter. It features interactive reading (tap-to-translate, full-sentence translation), a local Vocabulary Book (错词本), and a Supabase backend for managing real books and chapters.

## ✨ Features
- **Minimalist UI/UX:** Clean, monochromatic aesthetics with squircle cards, high contrast, and elegant typography (`Inter` for system, `Lora` for reading).
- **Interactive Reading:** Tap any word to get a dictionary lookup (Free Dictionary API + MyMemory API) with phonetics and examples.
- **Full Sentence Translation:** Click the `G Translate` icon at the end of any sentence to translate the entire context block into Chinese.
- **Smart Text Parsing:** Accurately detects sentence boundaries, ignoring common abbreviations (like `Mr.`, `Mrs.`, `Phd.`, `J. K. Rowling`).
- **Vocabulary Book:** Save unknown words along with their original context sentences. Stored locally using `shared_preferences`.
- **Chapter Navigation:** Pull up the Table of Contents drawer to jump between chapters, or use bottom navigation when finishing a chapter. Generates a beautiful "Completion Poster" to track your progress!
- **Unified Library & Web Search:** Search your local library instantly, or switch to "Search Web" to query the global Gutenberg public domain repository.
- **1-Click Cloud Import:** Found a book on Gutendex? Click "Import" in the app. A Python FastAPI backend automatically fetches the text, cleans the formatting, parses the chapters, resolves/generates a book cover, and syncs everything directly into your Supabase database in seconds.

---
## 🛠️ Technical Documentation & Architecture

### 1. Data Ingestion & Formatting (Python ETL)
*Scripts: `clean_and_import.py`, `upload_covers.py`*

**The Challenge:** Project Gutenberg raw text files use "hard wraps" (newlines fixed at ~70 characters) which breaks sentence context and mobile layout.
**Our Solution:** 
- A Python pipeline connects to the Supabase backend via `supabase-py`.
- **Regex Parsing:** Dynamically recognizes `CHAPTER` and `SCENE` tags to support both classic novels and play scripts.
- **Paragraph Re-construction:** Splits by double newlines (`\n\n`) to isolate true paragraphs. Single `\n` characters are swapped with spaces ` ` to reflow text seamlessly.
- **Cover Images:** Automatically provisions public storage buckets on Supabase, uploads local `ebooks/` covers, and associates the URLs to the database.

### 2. Sentence Boundary Detection & Translation
*Files: `text_parser.dart`, `dictionary_service.dart`, `interactive_paragraph.dart`*

**The Challenge:** Simple `.` matching for sentences breaks when encountering common abbreviations (e.g., `Mr.`, `Dr.`), fragmenting translations.
**Our Solution:**
- **Lookbehind Parsing:** `TextParser` checks the preceding token against a local `HashSet` of known abbreviations (`mr`, `mrs`, `dr`, `etc.`) or single-character initials. If matched, it bypasses the sentence break.
- **MyMemory API Integration:** Context-aware full sentence translations. The sentence index tracks identical tokens, reconstructing the string smoothly before the network fetch.

### 3. Reader Typography & UI/UX
*Files: `reader_screen.dart`, `app_theme.dart`*

**The Challenge:** Text felt homogenous; headers and dialog tags lacked typographic hierarchy. Book navigation was linear and tedious.
**Our Solution:**
- **Dynamic Header Formatting:** `InteractiveParagraph` computes context parameters. The first index of any chapter forces a header style (28px bold, centered). It also detects short, all-caps strings (like `SCENE I`) as subtitles automatically.
- **Chapter Navigation:** Rendered a modal bottom sheet Table of Contents driven by a Riverpod `FutureProvider`. Implemented intuitive `Next/Previous Chapter` buttons.

### 4. Vocabulary Notebook
*Files: `vocab_provider.dart`, `vocab_view.dart`*

**Architecture:**
Local persistence implemented with `shared_preferences`. Tapping tokens queries `DictionaryService`. Upon clicking "Add to Vocab", the word, phonetic, definitions, and contextual sentences are persisted to the device and accessible via the global library bottom navigation bar.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Supabase Project & Credentials

### Run the App
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Make sure you have a `.env` file in the root directory with `SUPABASE_URL` and `SUPABASE_ANON_KEY` configured.
4. Run the app using: `flutter run --dart-define-from-file=.env`

### Import Books
1. Add `.txt` files to the root directory
2. Update the Python script `clean_and_import.py` with your Supabase Secret Key
3. Run `python clean_and_import.py` to populate your database

### Automated Gutenberg Import (Gutendex)
You can now automatically fetch, parse, and import public domain books using our new ingestion pipeline.

1. Make sure you have your `.env` configured with `SUPABASE_URL` and `SUPABASE_KEY`.
2. (Optional but recommended) Run this SQL in your Supabase SQL Editor to support idempotency (avoiding duplicates):
   ```sql
   ALTER TABLE books ADD COLUMN IF NOT EXISTS source text DEFAULT 'gutendex';
   ALTER TABLE books ADD COLUMN IF NOT EXISTS external_id text;
   ```
3. Use the CLI tool:
   ```bash
   # Search and import a specific book
   python scripts/import_from_gutendex.py --query "Sherlock Holmes" --limit 1

   # Dry run (test parsing without saving to database)
   python scripts/import_from_gutendex.py --query "Alice in Wonderland" --limit 1 --dry-run

   # Import 5 popular English books and skip already imported ones
   python scripts/import_from_gutendex.py --language en --limit 5 --skip-existing
   ```

### 🎨 Managing Book Covers
The ingestion pipeline includes an automated three-tier cover resolution strategy:
1. **Gutendex Source**: Uses the original Gutenberg cover if available.
2. **Open Library API**: Falls back to searching Open Library by Title & Author.
3. **Auto-Generation**: Uses `Pillow` to dynamically draw a minimalist 2:3 book cover.

All covers are automatically uploaded to your Supabase `covers` storage bucket, and the `books.cover_url` is updated.

If you have old books in the database without covers, you can run the batch fixer:
```bash
# Optional: First add the cover_source column to track where images come from
# ALTER TABLE books ADD COLUMN IF NOT EXISTS cover_source text;

# Fix up to 10 books missing covers
python scripts/fix_missing_covers.py --limit 10

# Fix ALL books missing covers
python scripts/fix_missing_covers.py --all
```

### 🔌 Running the Backend API (FastAPI)
The Flutter application now supports an in-app "Search and 1-Click Import" feature that talks to a local Python FastAPI backend. This backend acts as a bridge, running the complex data ingestion pipelines (Gutendex search, smart sorting, text cleaning, and cover generation) without blocking the Flutter UI.

To enable this feature, you must run the FastAPI server:

1. Ensure you have the required dependencies: `pip install fastapi uvicorn requests python-dotenv`
2. Start the server from the root directory, ensuring it loads your `.env`:
   ```bash
   uvicorn backend.main:app --reload --env-file .env
   ```
3. The backend will run on `http://127.0.0.1:8000`, exposing endpoints for smart external search (prioritizing title matches) and 1-click importing.