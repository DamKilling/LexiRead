import os
from dotenv import load_dotenv
from supabase import create_client
from ingestion.cover_handler import CoverHandler

load_dotenv()
client = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
handler = CoverHandler(client)
url, source = handler.process_cover("Dracula Test", "Bram Stoker", "https://www.gutenberg.org/cache/epub/345/pg345.cover.medium.jpg")
print("URL:", url)
print("Source:", source)
