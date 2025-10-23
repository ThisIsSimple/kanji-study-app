#!/usr/bin/env python3
import json
import csv
import os

def save_ku_to_csv():
    with open("crawl_progress.json", "r") as f:
        data = json.load(f)
    
    if "く" not in data.get("data", {}):
        print("く data not found")
        return False
    
    ku_data = data["data"]["く"]
    songs = ku_data.get("songs", [])
    
    if not songs:
        print("No songs found for く")
        return False
    
    os.makedirs("song_lists/indexes", exist_ok=True)
    
    csv_path = "song_lists/indexes/く.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as csvfile:
        fieldnames = ["title", "url", "artist", "songwriter", "composer", "preview"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for song in songs:
            writer.writerow({
                "title": song.get("title", ""),
                "url": song.get("url", ""),
                "artist": song.get("artist", ""),
                "songwriter": song.get("songwriter", ""),
                "composer": song.get("composer", ""),
                "preview": song.get("preview", "")
            })
    
    print(f"Successfully saved {len(songs):,} songs to {csv_path}")
    return True

if __name__ == "__main__":
    save_ku_to_csv()
