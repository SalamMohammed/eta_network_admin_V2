import json
import glob
import os

def get_keys(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        try:
            data = json.load(f)
            # Filter out keys starting with @
            return {k: v for k, v in data.items() if not k.startswith('@') and k != "@@locale"}
        except json.JSONDecodeError as e:
            print(f"Error parsing {file_path}: {e}")
            return {}

def check_missing_keys():
    base_dir = r"d:\EtaNetwork\eta_network_admin_V2\lib\l10n"
    en_path = os.path.join(base_dir, "app_en.arb")
    
    if not os.path.exists(en_path):
        print(f"Base file {en_path} not found!")
        return

    en_keys = get_keys(en_path)
    en_key_set = set(en_keys.keys())
    
    print(f"Found {len(en_key_set)} keys in app_en.arb")
    
    arb_files = glob.glob(os.path.join(base_dir, "app_*.arb"))
    
    missing_summary = {}
    
    for arb_file in arb_files:
        if arb_file == en_path:
            continue
            
        filename = os.path.basename(arb_file)
        # Skip if it's the template or meta file if any (though typically app_en is the template)
        
        file_keys = get_keys(arb_file)
        file_key_set = set(file_keys.keys())
        
        missing = en_key_set - file_key_set
        
        if missing:
            print(f"\n{filename}: Missing {len(missing)} keys")
            # print(f"Missing keys: {', '.join(sorted(list(missing)))}")
            missing_summary[filename] = list(missing)
        else:
            print(f"\n{filename}: Complete")

    # Generate a report of what needs to be fixed
    if missing_summary:
        print("\n\nSummary of files to fix:")
        for filename, keys in missing_summary.items():
            print(f"- {filename} ({len(keys)} missing)")
            # Print first few missing keys as examples
            print(f"  Examples: {', '.join(sorted(keys)[:5])}...")

if __name__ == "__main__":
    check_missing_keys()
