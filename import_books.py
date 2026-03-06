import os
import re
from supabase import create_client, Client

# ==========================================
# 1. 填写您的 Supabase 配置
# 注意：为了有写入权限，推荐使用 Supabase Dashboard -> Project Settings -> API 里的 "service_role" secret key，而不是 anon key。
# ==========================================
SUPABASE_URL = "https://njxzcpgnxbcjgxinzafa.supabase.co"
SUPABASE_KEY = "***REMOVED_SECRET***"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def import_book_from_txt(txt_path, title, author, cover_url, difficulty):
    """
    读取 txt 文件并自动拆分章节存入 Supabase
    """
    print(f"开始处理书籍: {title}...")

    # 1. 读取本地 txt 文件
    with open(txt_path, 'r', encoding='utf-8') as file:
        content = file.read()
    # 2. 将书籍基础信息写入 books 表
    book_data = {
        "title": title,
        "author": author,
        "cover_url": cover_url,
        "difficulty_level": difficulty,
        "description": f"A classic book: {title}",
        "total_chapters": 0  # 先填0，稍后更新
    }

    # 执行插入并获取返回的数据（里面包含数据库生成的 UUID）
    book_res = supabase.table("books").insert(book_data).execute()
    book_id = book_res.data[0]['id']
    print(f"书籍创建成功，ID: {book_id}")
    # 3. 智能切割章节
    # 对《罗密欧与朱丽叶》这类的剧本，使用 SCENE 来进行切分更合适。使用捕获组保留 SCENE 的标题
    # 对于《呼啸山庄》，使用 CHAPTER 进行切分。兼容两者。
    raw_chunks = re.split(r'(?im)(^(?:CHAPTER|SCENE)\s+[A-ZIVX0-9]+\.*.*)', content)

    # re.split 带有捕获组时，会返回 [文本1, 匹配项1, 文本2, 匹配项2...]
    # 我们需要把 "SCENE I..." 和后面的内容拼接起来作为完整的章节
    raw_chapters = []
    if len(raw_chunks) > 0:
        # 第一段通常是版权声明、目录或前言，如果有实质内容也可以作为 Prologue
        raw_chapters.append(("Prologue / Intro", raw_chunks[0]))
        for i in range(1, len(raw_chunks), 2):
            scene_title = raw_chunks[i].strip()
            scene_content = raw_chunks[i+1] if i+1 < len(raw_chunks) else ""
            raw_chapters.append((scene_title, scene_title + "\n\n" + scene_content.strip()))

    chapter_number = 1
    inserted_chapters = 0

    for title, text_block in raw_chapters:
        text_block = text_block.strip()

        # 忽略古腾堡开头那一长串的版权声明和前言，或者太短的无效段落
        if not text_block or len(text_block) < 200:
            continue

        # 去掉结尾古腾堡的版权声明尾巴
        if "*** END OF THE PROJECT GUTENBERG" in text_block:
            text_block = text_block.split("*** END OF THE PROJECT GUTENBERG")[0].strip()

        # 简单统计单词数
        word_count = len(text_block.split())

        chapter_data = {
            "book_id": book_id,
            "chapter_number": chapter_number,
            "title": title[:50],  # 截取合理的长度作为标题
            "content": text_block,
            "word_count": word_count
        }

        # 写入章节表
        supabase.table("chapters").insert(chapter_data).execute()
        print(f"  -> 成功插入 {title[:30]}...，字数: {word_count} 词")

        chapter_number += 1
        inserted_chapters += 1

    # 4. 更新书籍的总章节数
    supabase.table("books").update({"total_chapters": inserted_chapters}).eq("id", book_id).execute()
    print(f"导入完毕！本书共 {inserted_chapters} 章。\n")


if __name__ == "__main__":
    # ==========================================
    # 使用示例
    # ==========================================

    import_book_from_txt(
        txt_path="Wuthering.txt",
        title="Wuthering Heights",
        author="Emily Brontë",
        cover_url="https://images.unsplash.com/photo-1518174454942-0f5da812f865?q=80&w=500",
        difficulty="C1"
    )