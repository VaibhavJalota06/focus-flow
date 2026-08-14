import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

def render_premium_dart_target(size=1024):
    scale = 4  # 4x supersampling for razor sharp vector rendering
    W = size * scale
    H = size * scale
    cx, cy = W // 2, H // 2

    # 1. Luxurious dark background squircle with subtle glass border
    pad = int(W * 0.04)
    r_corner = int(W * 0.22)
    bg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    
    # Deep obsidian dark background
    bg_draw.rounded_rectangle([pad, pad, W - pad, H - pad], radius=r_corner, fill=(16, 18, 28, 255))
    
    # Soft background neon glow bloom behind target
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    for rad in range(int(W * 0.45), 0, -12):
        t = rad / (W * 0.45)
        alpha = int(45 * (1 - t))
        g_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(255, 45, 85, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=int(scale * 30)))
    bg = Image.alpha_composite(bg, glow)

    # 2. Main Dartboard / Target (Fills 74% of canvas so it is BIG, BOLD, AND PROMINENT)
    target_radius = int(W * 0.37)

    # Target Drop Shadow
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_offset = int(scale * 16)
    s_draw.ellipse([cx - target_radius, cy - target_radius + s_offset, cx + target_radius, cy + target_radius + s_offset], fill=(0, 0, 0, 160))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=int(scale * 18)))
    bg = Image.alpha_composite(bg, shadow)

    # Render Concentric Rings with rich gradients & 3D bevel
    board = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(board)

    # Outer border ring (Dark charcoal steel rim)
    rim_r = target_radius
    b_draw.ellipse([cx - rim_r, cy - rim_r, cx + rim_r, cy + rim_r], fill=(35, 38, 52, 255))
    b_draw.ellipse([cx - rim_r, cy - rim_r, cx + rim_r, cy + rim_r], outline=(255, 255, 255, 70), width=int(scale * 4))

    # Ring radii (Outer to Bullseye)
    r1 = int(target_radius * 0.94)  # Outer Red
    r2 = int(target_radius * 0.74)  # White 1
    r3 = int(target_radius * 0.54)  # Red 2
    r4 = int(target_radius * 0.34)  # White 2
    r5 = int(target_radius * 0.18)  # Bullseye Red Center

    # Ring 1: Vibrant Red with subtle gradient
    b_draw.ellipse([cx - r1, cy - r1, cx + r1, cy + r1], fill=(255, 45, 85, 255))
    # Ring 2: Crisp Bright White / Ice
    b_draw.ellipse([cx - r2, cy - r2, cx + r2, cy + r2], fill=(245, 248, 255, 255))
    # Ring 3: Vibrant Crimson Red
    b_draw.ellipse([cx - r3, cy - r3, cx + r3, cy + r3], fill=(255, 45, 85, 255))
    # Ring 4: Crisp White
    b_draw.ellipse([cx - r4, cy - r4, cx + r4, cy + r4], fill=(245, 248, 255, 255))
    # Ring 5: Glowing Core Bullseye
    b_draw.ellipse([cx - r5, cy - r5, cx + r5, cy + r5], fill=(255, 30, 60, 255))

    # Groove outlines between rings
    for r_groove in [r1, r2, r3, r4, r5]:
        b_draw.ellipse([cx - r_groove, cy - r_groove, cx + r_groove, cy + r_groove], outline=(0, 0, 0, 40), width=int(scale * 2))

    # 3D Spherical Light / Gloss Overlay on Dartboard
    board_gloss = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bg_gloss_draw = ImageDraw.Draw(board_gloss)
    bg_gloss_draw.ellipse([cx - int(target_radius * 0.85), cy - int(target_radius * 0.9), cx + int(target_radius * 0.4), cy - int(target_radius * 0.1)], fill=(255, 255, 255, 45))
    board_gloss = board_gloss.filter(ImageFilter.GaussianBlur(radius=int(scale * 16)))
    board = Image.alpha_composite(board, board_gloss)

    # 3. 3D Electric Blue Dart hitting Center
    dart_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(dart_img)

    angle_deg = 36
    rad = math.radians(angle_deg)
    cos_a, sin_a = math.cos(rad), math.sin(rad)
    perp_cos, perp_sin = -sin_a, cos_a

    p_tip = (cx, cy)
    barrel_len = int(target_radius * 0.55)
    shaft_len = int(target_radius * 0.95)
    flight_end = int(target_radius * 1.35)

    p_barrel_start = (cx + int(barrel_len * 0.3 * cos_a), cy - int(barrel_len * 0.3 * sin_a))
    p_barrel_end   = (cx + int(barrel_len * cos_a), cy - int(barrel_len * sin_a))
    p_shaft_end    = (cx + int(shaft_len * cos_a), cy - int(shaft_len * sin_a))
    p_flight_end   = (cx + int(flight_end * cos_a), cy - int(flight_end * sin_a))

    # Dart Shadow on board
    d_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ds_draw = ImageDraw.Draw(d_shadow)
    sh_offset_x = int(scale * 12)
    sh_offset_y = int(scale * 24)
    ds_draw.line([(cx + sh_offset_x, cy + sh_offset_y), 
                  (p_flight_end[0] + sh_offset_x, p_flight_end[1] + sh_offset_y)], 
                 fill=(0, 0, 0, 140), width=int(scale * 22))
    d_shadow = d_shadow.filter(ImageFilter.GaussianBlur(radius=int(scale * 10)))
    board = Image.alpha_composite(board, d_shadow)

    # Silver / Steel Needle Tip
    d_draw.line([p_tip, p_barrel_start], fill=(220, 230, 245, 255), width=int(scale * 7))

    # Metallic / Cobalt Grip Barrel
    d_draw.line([p_barrel_start, p_barrel_end], fill=(0, 160, 255, 255), width=int(scale * 16))
    d_draw.line([p_barrel_start, p_barrel_end], fill=(160, 230, 255, 255), width=int(scale * 8))

    # Sleek Dart Shaft (Electric Cyan)
    d_draw.line([p_barrel_end, p_shaft_end], fill=(0, 122, 255, 255), width=int(scale * 10))
    d_draw.line([p_barrel_end, p_shaft_end], fill=(100, 210, 255, 255), width=int(scale * 4))

    # Aerodynamic Flights / Wings
    wing_span = int(target_radius * 0.32)
    
    # Wing 1
    w1_p1 = p_shaft_end
    w1_p2 = (p_shaft_end[0] + int(wing_span * perp_cos), p_shaft_end[1] - int(wing_span * perp_sin))
    w1_p3 = (p_flight_end[0] + int((wing_span * 0.7) * perp_cos), p_flight_end[1] - int((wing_span * 0.7) * perp_sin))
    w1_p4 = p_flight_end
    d_draw.polygon([w1_p1, w1_p2, w1_p3, w1_p4], fill=(0, 195, 255, 255))
    d_draw.polygon([w1_p1, w1_p2, w1_p3, w1_p4], outline=(255, 255, 255, 220), width=int(scale * 3))

    # Wing 2
    w2_p1 = p_shaft_end
    w2_p2 = (p_shaft_end[0] - int(wing_span * perp_cos), p_shaft_end[1] + int(wing_span * perp_sin))
    w2_p3 = (p_flight_end[0] - int((wing_span * 0.7) * perp_cos), p_flight_end[1] + int((wing_span * 0.7) * perp_sin))
    w2_p4 = p_flight_end
    d_draw.polygon([w2_p1, w2_p2, w2_p3, w2_p4], fill=(0, 130, 255, 255))
    d_draw.polygon([w2_p1, w2_p2, w2_p3, w2_p4], outline=(255, 255, 255, 180), width=int(scale * 3))

    # Center Flight spine
    d_draw.line([p_shaft_end, p_flight_end], fill=(255, 255, 255, 255), width=int(scale * 8))

    # Bullseye Impact Sparkle
    impact_r = int(scale * 8)
    d_draw.ellipse([cx - impact_r, cy - impact_r, cx + impact_r, cy + impact_r], fill=(255, 255, 255, 255))

    final = Image.alpha_composite(bg, board)
    final = Image.alpha_composite(final, dart_img)

    # 4. Outer Glass Rim Highlight
    card_rim = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cr_draw = ImageDraw.Draw(card_rim)
    cr_draw.rounded_rectangle([pad, pad, W - pad, H - pad], radius=r_corner, outline=(255, 255, 255, 40), width=int(scale * 4))
    final = Image.alpha_composite(final, card_rim)

    return final.resize((size, size), Image.Resampling.LANCZOS)

def generate_all():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    base_res = os.path.join(project_root, "android", "app", "src", "main", "res")
    asset_icon_dir = os.path.join(project_root, "assets", "icons")
    os.makedirs(asset_icon_dir, exist_ok=True)

    print("Rendering High-Definition Focus Flow Target Logo (1024x1024)...")
    master = render_premium_dart_target(1024)

    # Save Flutter Asset Icon
    asset_path = os.path.join(asset_icon_dir, "app_icon.png")
    master.save(asset_path, "PNG")
    print(f"Saved asset: {asset_path}")

    # Export all Android Mipmaps
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    for folder, dim in sizes.items():
        folder_path = os.path.join(base_res, folder)
        os.makedirs(folder_path, exist_ok=True)

        scaled = master.resize((dim, dim), Image.Resampling.LANCZOS)
        out_path = os.path.join(folder_path, "ic_launcher.png")
        scaled.save(out_path, "PNG")

        mask = Image.new("L", (dim, dim), 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse((0, 0, dim, dim), fill=255)
        round_img = Image.new("RGBA", (dim, dim), (0, 0, 0, 0))
        round_img.paste(scaled, (0, 0), mask=mask)
        round_path = os.path.join(folder_path, "ic_launcher_round.png")
        round_img.save(round_path, "PNG")

        print(f"Saved {folder}: {dim}x{dim}")

    print("HD Dart-Target Logo generation completed successfully!")

if __name__ == "__main__":
    generate_all()
