import json
import shutil

with open("scripts/config.json", "r") as file:
  config = json.load(file)
  
  # Get GTA SA dir.
  try:
    gta_sa_dir = config["gta-sa-dir"]
  except KeyError:
    print("Can't copy `moonly.lua` without property `gta-sa-dir`")
    exit()
    
  shutil.copy("src/moonly.lua", gta_sa_dir + "/moonloader")
  