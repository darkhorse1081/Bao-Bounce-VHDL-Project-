from PIL import Image

# Color Palette for our 3-bit system
COLORS = {
    "000": (0, 0, 0),       # Black
    "010": (0, 255, 0),     # Green
    "100": (255, 0, 0),     # Red/Brown
    "110": (255, 255, 0),   # Yellow
    "111": (255, 255, 255), # White
    "101": (255, 0, 255)    # Magenta (Transparent)
}

def generate_assets(filename, width, height, pixel_data):
    # 1. Create the PNG so you can look at it
    img = Image.new('RGB', (width, height))
    pixels = img.load()
    
    # 2. Create the MIF for the FPGA
    mif = f"DEPTH = {width*height};\nWIDTH = 3;\nADDRESS_RADIX = UNS;\nDATA_RADIX = BIN;\nCONTENT BEGIN\n"
    
    for i, color_bin in enumerate(pixel_data):
        # Calculate X and Y from the flat list
        x = i % width
        y = i // width
        pixels[x, y] = COLORS[color_bin]
        mif += f"{i} : {color_bin};\n"
        
    mif += "END;\n"
    
    # Save both files
    img.save(f"{filename}.png")
    with open(f"{filename}.mif", "w") as f:
        f.write(mif)
    print(f"Saved {filename}.png and {filename}.mif!")

# --- 1. THE PIPE CAP (50x16) ---
pipecap_pixels = []
for y in range(16):
    for x in range(50):
        if y == 0 or y == 15: color = "000"
        elif x <= 1 or x >= 48: color = "000"
        elif 3 <= x <= 5: color = "111"
        elif 43 <= x <= 47: color = "000"
        else: color = "010"
        pipecap_pixels.append(color)

generate_assets("pipecap", 50, 16, pipecap_pixels)

# --- 2. THE SCROLLING GROUND TEXTURE (16x16) ---
ground_pixels = []
for y in range(16):
    for x in range(16):
        if y < 2: color = "010" # Grass
        elif y == 2: color = "000" # Outline
        else:
            if (x + y) % 16 < 8: color = "110" # Yellow dirt
            else: color = "100" # Brown dirt
        ground_pixels.append(color)

generate_assets("ground", 16, 16, ground_pixels)