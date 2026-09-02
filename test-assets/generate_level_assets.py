from PIL import Image

# 3-Bit Color Palette (R, G, B) mapping
COLORS = {
    'BLK': (0, 0, 0),       # 000 - Black (Outline)
    'BLU': (0, 0, 255),     # 001 - Blue
    'GRN': (0, 255, 0),     # 010 - Green
    'CYN': (0, 255, 255),   # 011 - Cyan
    'RED': (255, 0, 0),     # 100 - Red
    'MAG': (255, 0, 255),   # 101 - Magenta (TRANSPARENT)
    'YLW': (255, 255, 0),   # 110 - Yellow (Coin Body)
    'WHT': (255, 255, 255)  # 111 - White (Highlight)
}

# The 20x20 Coin Pixel Map (M=Magenta/Transparent, B=Black, Y=Yellow, W=White)
coin_art = [
    "MMMMMMBBBBBBBBMMMMMM",
    "MMMMBBYYYYYYYYBBMMMM",
    "MMMBYYYYYYYYYYYYBMMM",
    "MMBYYYYWWWWYYYYYYBMM",
    "MBYYYYWYYYYWYYYYYYBM",
    "MBYYYYWWWWWWYYYYYYBM",
    "BYYYYYWYYYYWYYYYYYYB",
    "BYYYYYYWWWWYYYYYYYYB",
    "BYYYYYYYYYYYYYYYYYYB",
    "BYYYYYYYYYYYYYYYYYYB",
    "BYYYYYYBBBBYYYYYYYYB",
    "BYYYYYYBWWBYYYYYYYYB",
    "BYYYYYYBWWBYYYYYYYYB",
    "MBYYYYYBBBBYYYYYYYBM",
    "MBYYYYYYYYYYYYYYYYBM",
    "MMBYYYYYYYYYYYYYYBMM",
    "MMMBYYYYYYYYYYYYBMMM",
    "MMMMBBYYYYYYYYBBMMMM",
    "MMMMMMBBBBBBBBMMMMMM",
    "MMMMMMMMMMMMMMMMMMMM"
]

# 1. Generate the PNG Image
img = Image.new('RGB', (20, 20))
pixels = img.load()

# 2. Generate the MIF file content
mif_content = "DEPTH = 400;\nWIDTH = 3;\nADDRESS_RADIX = UNS;\nDATA_RADIX = BIN;\nCONTENT BEGIN\n"

addr = 0
for y in range(20):
    for x in range(20):
        char = coin_art[y][x]
        
        if char == 'M':   color, bin_val = COLORS['MAG'], "101"
        elif char == 'B': color, bin_val = COLORS['BLK'], "000"
        elif char == 'Y': color, bin_val = COLORS['YLW'], "110"
        elif char == 'W': color, bin_val = COLORS['WHT'], "111"
            
        pixels[x, y] = color
        mif_content += f"{addr} : {bin_val};\n"
        addr += 1

mif_content += "END;\n"

# Save files
img.save("gift.png")
with open("gift.mif", "w") as f:
    f.write(mif_content)

print("Successfully generated gift.png and gift.mif!")

# generate_level_assets.py
# Run this in Python to generate your .mif files

def create_mif(filename, width, height, pixel_data):
    mif = f"DEPTH = {width*height};\nWIDTH = 3;\nADDRESS_RADIX = UNS;\nDATA_RADIX = BIN;\nCONTENT BEGIN\n"
    for addr, color in enumerate(pixel_data):
        mif += f"{addr} : {color};\n"
    mif += "END;\n"
    with open(filename, "w") as f:
        f.write(mif)
    print(f"Generated {filename}")

# --- 1. THE PIPE CAP (50x16) ---
# Colors: 000=Black, 010=Green, 111=White, 101=Magenta(Transparent)
pipecap_pixels = []
for y in range(16):
    for x in range(50):
        # Top and Bottom Black Borders
        if y == 0 or y == 15: color = "000"
        # Left and Right Black Borders
        elif x <= 1 or x >= 48: color = "000"
        # White Highlight on the left
        elif 3 <= x <= 5: color = "111"
        # Black Shadow on the right
        elif 43 <= x <= 47: color = "000"
        # Green Body
        else: color = "010"
        
        pipecap_pixels.append(color)

create_mif("pipecap.mif", 50, 16, pipecap_pixels)

# --- 2. THE SCROLLING GROUND TEXTURE (16x16) ---
# Colors: 010=Green(Grass), 000=Black, 110=Yellow, 100=Red
ground_pixels = []
for y in range(16):
    for x in range(16):
        # Top 2 rows are green grass
        if y < 2: color = "010"
        # 3rd row is a black outline separating grass from dirt
        elif y == 2: color = "000"
        else:
            # Create diagonal dirt stripes using modulo math!
            if (x + y) % 16 < 8:
                color = "110" # Yellow dirt
            else:
                color = "100" # Red/Brown dirt
                
        ground_pixels.append(color)

create_mif("ground.mif", 16, 16, ground_pixels)