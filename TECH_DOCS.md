# LexiRead - Technical Documentation & Fixes

## 1. Data Ingestion & Formatting
*Script Location: `clean_and_import.py`, `upload_covers.py`*

**Issue:** 
Project Gutenberg raw text files use "hard wraps" (newlines fixed at ~70 characters). When rendered directly in Flutter, this causes unnatural breaks in sentences, rendering "Translate Sentence" features and paragraph layouts broken.

**Solution:**
We developed a Python ETL script that cleans text before it enters the Supabase backend.
- **Regex Parsing:** Recognizes `CHAPTER` and `SCENE` tags dynamically to support both classic novels and scripts.
- **Paragraph Re-construction:** Splitting by double newlines `\n\n` to isolate true paragraphs. Within each block, single `\n` characters are swapped with spaces ` ` to reflow text seamlessly.
- **Automated Book Configuration:** Python scripts communicate via `supabase-py` to instantiate books, auto-compute total chapters, and associate word counts.
- **Cover Images:** Script automatically provisions public storage buckets on Supabase and uploads images, associating the public URL to the `books` table.

## 2. Sentence Boundary Detection & Translation
*Files: `text_parser.dart`, `dictionary_service.dart`, `interactive_paragraph.dart`*

**Issue:** 
The reader interprets tokens and boundaries. Simple dot `.` matching for sentences breaks when encountering common abbreviations (e.g., `Mr.`, `Dr.`), fragmenting the sentence translation logic.

**Solution:**
- **Lookbehind parsing:** In `TextParser`, when punctuation ending in `.` is encountered, the algorithm checks the preceding token against a local `HashSet` of known abbreviations (`mr`, `mrs`, `dr`, `etc`, etc.) or single-character initials (`J. K. Rowling`). If matched, it bypasses the sentence incrementer.
- **MyMemory API Integration:** Using `http` requests to `api.mymemory.translated.net` to provide context-aware full sentence translations. The sentence index tracks identical tokens, reconstructing the string smoothly before network fetch.

## 3. Reader Typography & UI/UX
*Files: `reader_screen.dart`, `app_theme.dart`*

**Issue:** 
Text felt homogenous; headers and dialog tags lacked typographic hierarchy. Book navigation was linear and tedious.

**Solution:**
- **Dynamic Header Formatting:** `InteractiveParagraph` now computes context parameters. The first index of any chapter forces a header style (28px bold, centered). Additionally, it detects short, all-caps strings (`SCENE I`, character names) as subtitles automatically scaling font-size and weight while hiding the translate button to keep the visual flow clean.
- **Minimalist Aesthetic:** Transitioned styling to an Apple-like monochromatic schema utilizing `GoogleFonts.lora` for serifs and `GoogleFonts.inter` for system fonts. Cards use 0.05 opacity borders and squircle radii.
- **Chapter Navigation:** 
  - Rendered a modal bottom sheet Table of Contents, driven by a `FutureProvider` hitting the `chapters` Supabase table.
  - Implemented intuitive `Next Chapter` and `Previous Chapter` buttons at the end of scroll.
  - Finished chapters invoke `CompletionPoster`, rewarding users and giving an immediate callback to continue reading.

## 4. Vocabulary Notebook
*Files: `vocab_provider.dart`, `vocab_view.dart`*

**Architecture:**
Local persistence implemented with `shared_preferences`. Tapping specific tokens queries `DictionaryService` (combining Free Dictionary API and MyMemory). Upon "Add to Vocab", word, phonetic, definitions, and contextual sentences are persisted to the device and accessible via the global library bottom navigation bar.
