import os
from supabase import create_client, Client

SUPABASE_URL = "https://njxzcpgnxbcjgxinzafa.supabase.co"
SUPABASE_KEY = "***REMOVED_SECRET***"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def upload_cover(file_path, file_name):
    bucket_name = "covers"
    
    # 尝试创建 bucket，如果已经存在会忽略错误
    try:
        supabase.storage.create_bucket(bucket_name, public=True)
    except Exception as e:
        pass
        
    with open(file_path, 'rb') as f:
        try:
            supabase.storage.from_(bucket_name).upload(file_name, f.read(), {"content-type": "image/jpeg", "upsert": "true"})
            print(f"Uploaded {file_name}")
        except Exception as e:
            print(f"Failed to upload {file_name}: {e}")
            try:
                supabase.storage.from_(bucket_name).update(file_name, f.read(), {"content-type": "image/jpeg", "upsert": "true"})
                print(f"Updated {file_name}")
            except Exception as e2:
                print(f"Failed to update {file_name}: {e2}")

    public_url = supabase.storage.from_(bucket_name).get_public_url(file_name)
    return public_url

def update_book_cover(book_title, cover_url):
    res = supabase.table("books").update({"cover_url": cover_url}).eq("title", book_title).execute()
    print(f"Updated cover for {book_title}")

if __name__ == "__main__":
    covers = [
        {"file": "ebooks/pg1513.cover.medium.jpg", "title": "Romeo and Juliet"},
        {"file": "ebooks/pg768.cover.medium.jpg", "title": "Wuthering Heights"}
    ]
    
    for item in covers:
        if os.path.exists(item["file"]):
            file_name = os.path.basename(item["file"])
            url = upload_cover(item["file"], file_name)
            print(f"Public URL for {item['title']}: {url}")
            update_book_cover(item["title"], url)
        else:
            print(f"File not found: {item['file']}")
