import math
import os
from PIL import Image, ImageDraw, ImageFilter

def render_circular_target_logo(size=1024):
    scale = 4  # 4x supersampling for razor sharp vector edges
    W = size * scale
    H = size * scale
    cx, cy = W // 2, H // 2

    # Canvas (RGBA)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    # 1. Soft glowing coral / red halo ring background (like in user screenshot)
    halo_radius = int(W * 0.44)
    halo_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    h_draw = ImageDraw.Draw(halo_img)
    
    # Outer ambient glow bloom
    for rad in range(int(W * 0.48), int(W * 0.35), -8):
        t = (rad - int(W * 0.35)) / (int(W * 0.48) - int(W * 0.35))
        alpha = int(40 * (1 - t))
        h_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(255, 75, 75, alpha))

    # Soft circular badge container
    h_draw.ellipse([cx - halo_radius, cy - halo_radius, cx + halo_radius, cy + halo_radius], 
                   fill=(255, 120, 120, 70))
    h_draw.ellipse([cx - halo_radius, cy - halo_radius, cx + halo_radius, cy + halo_radius], 
                   outline=(255, 80, 80, 160), width=int(scale * 4))

    halo_img = halo_img.filter(ImageFilter.GaussianBlur(radius=int(scale * 4)))
    img = Image.alpha_composite(img, halo_img)

    # 2. Main Red & White Concentric Target Board
    target_radius = int(W * 0.28)

    # Drop shadow under target
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_offset = int(scale * 10)
    s_draw.ellipse([cx - target_radius, cy - target_radius + s_offset, 
                    cx + target_radius, cy + target_radius + s_offset], fill=(0, 0, 0, 80))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=int(scale * 12)))
    img = Image.alpha_composite(img, shadow)

    # Render Concentric Rings
    board = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(board)

    # Ring Radii: Outer Red -> White -> Red -> White -> Center Red
    r_red_1 = target_radius
    r_white_1 = int(target_radius * 0.80)
    r_red_2 = int(target_radius * 0.60)
    r_white_2 = int(target_radius * 0.40)
    r_red_3 = int(target_radius * 0.20)

    # Vibrant Crimson Red & Crisp Ice White
    red_color = (255, 38, 56, 255)
    white_color = (255, 255, 255, 255)

    b_draw.ellipse([cx - r_red_1, cy - r_red_1, cx + r_red_1, cy + r_red_1], fill=red_color)
    b_draw.ellipse([cx - r_white_1, cy - r_white_1, cx + r_white_1, cy + r_white_1], fill=white_color)
    b_draw.ellipse([cx - r_red_2, cy - r_red_2, cx + r_red_2, cy + r_red_2], fill=red_color)
    b_draw.ellipse([cx - r_white_2, cy - r_white_2, cx + r_white_2, cy + r_white_2], fill=white_color)
    b_draw.ellipse([cx - r_red_3, cy - r_red_3, cx + r_red_3, cy + r_red_3], fill=red_color)

    # Subtle inner bevel / shadow on bottom-right of target for depth
    bevel = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bev_draw = ImageDraw.Draw(bevel)
    bev_draw.ellipse([cx - target_radius + int(scale * 4), cy - target_radius + int(scale * 8), 
                      cx + target_radius, cy + target_radius], fill=(0, 0, 0, 30))
    bevel = bevel.filter(ImageFilter.GaussianBlur(radius=int(scale * 8)))
    
    board = Image.alpha_composite(board, bevel)

    # 3. Vibrant Blue Dart hitting Bullseye
    dart_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(dart_img)

    # Dart Angle: ~40 degrees pointing down-left into bullseye (cx, cy)
    angle_deg = 40
    rad = math.radians(angle_deg)
    cos_a, sin_a = math.cos(rad), math.sin(rad)
    perp_cos, perp_sin = -sin_a, cos_a

    p_tip = (cx, cy)
    shaft_len = int(target_radius * 0.85)
    flight_len = int(target_radius * 1.30)

    p_shaft_start = (cx + int(target_radius * 0.15 * cos_a), cy - int(target_radius * 0.15 * sin_a))
    p_shaft_end   = (cx + int(shaft_len * cos_a), cy - int(shaft_len * sin_a))
    p_flight_end  = (cx + int(flight_len * cos_a), cy - int(flight_len * sin_a))

    # Dart Shadow on board
    d_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ds_draw = ImageDraw.Draw(d_shadow)
    sh_x, sh_y = int(scale * 8), int(scale * 16)
    ds_draw.line([(cx + sh_x, cy + sh_y), (p_flight_end[0] + sh_x, p_flight_end[1] + sh_y)], 
                 fill=(0, 0, 0, 110), width=int(scale * 16))
    d_shadow = d_shadow.filter(ImageFilter.GaussianBlur(radius=int(scale * 6)))
    board = Image.alpha_composite(board, d_shadow)

    # Dart Needle (Silver tip)
    d_draw.line([p_tip, p_shaft_start], fill=(220, 230, 245, 255), width=int(scale * 6))

    # Dart Shaft (Electric Cobalt Blue)
    blue_body = (0, 122, 255, 255)
    blue_highlight = (80, 190, 255, 255)
    d_draw.line([p_shaft_start, p_shaft_end], fill=blue_body, width=int(scale * 12))
    d_draw.line([p_shaft_start, p_shaft_end], fill=blue_highlight, width=int(scale * 4))

    # Dart Flights / Feathers (Cyan/Electric Blue)
    wing_w = int(target_radius * 0.36)
    w_color = (0, 150, 255, 255)
    w_edge = (255, 255, 255, 200)

    # Top Flight Wing
    p1 = p_shaft_end
    p2 = (p_shaft_end[0] + int(wing_w * perp_cos), p_shaft_end[1] - int(wing_w * perp_sin))
    p3 = (p_flight_end[0] + int(wing_w * 0.8 * perp_cos), p_flight_end[1] - int(wing_w * 0.8 * perp_sin))
    p4 = p_flight_end
    d_draw.polygon([p1, p2, p3, p4], fill=w_color)
    d_draw.polygon([p1, p2, p3, p4], outline=w_edge, width=int(scale * 2))

    # Bottom Flight Wing
    p2_b = (p_shaft_end[0] - int(wing_w * perp_cos), p_shaft_end[1] + int(wing_w * perp_sin))
    p3_b = (p_flight_end[0] - int(wing_w * 0.8 * perp_cos), p_flight_end[1] + int(wing_w * 0.8 * perp_sin))
    d_draw.polygon([p1, p2_b, p3_b, p4], fill=(0, 110, 240, 255))
    d_draw.polygon([p1, p2_b, p3_b, p4], outline=w_edge, width=int(scale * 2))

    # Center Flight Spine
    d_draw.line([p_shaft_end, p_flight_end], fill=(255, 255, 255, 255), width=int(scale * 6))

    # Impact Flash at Bullseye Center
    impact_r = int(scale * 6)
    d_draw.ellipse([cx - impact_r, cy - impact_r, cx + impact_r, cy + impact_r], fill=(255, 255, 255, 255))

    img = Image.alpha_composite(img, board)
    img = Image.alpha_composite(img, dart_img)

    return img.resize((size, size), Image.Resampling.LANCZOS)

def generate_and_save():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    base_res = os.path.join(project_root, "android", "app", "src", "main", "res")
    asset_icon_dir = os.path.join(project_root, "assets", "icons")
    os.makedirs(asset_icon_dir, exist_ok=True)

    print("Rendering Exact Circular Glowing Target Logo (1024x1024)...")
    master = render_circular_target_logo(1024)

    # Save Flutter Asset Icon
    asset_path = os.path.join(asset_icon_dir, "app_icon.png")
    master.save(asset_path, "PNG")
    print(f"Saved asset: {asset_path}")

    # Also save preview in brain folder for immediate viewing
    brain_path = r"C:\Users\Vaibhav Jalota\.gemini\antigravity-ide\brain\35dd4525-4cb8-49f6-8786-e37486ed8117\target_logo_preview.png"
    master.save(brain_path, "PNG")

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

        round_path = os.path.join(folder_path, "ic_launcher_round.png")
        scaled.save(round_path, "PNG")

        print(f"Saved {folder}: {dim}x{dim}")

    # Export all iOS AppIcon sizes
    ios_icon_dir = os.path.join(project_root, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    if os.path.exists(ios_icon_dir):
        ios_sizes = {
            "Icon-App-20x20@1x.png": 20,
            "Icon-App-20x20@2x.png": 40,
            "Icon-App-20x20@3x.png": 60,
            "Icon-App-29x29@1x.png": 29,
            "Icon-App-29x29@2x.png": 58,
            "Icon-App-29x29@3x.png": 87,
            "Icon-App-40x40@1x.png": 40,
            "Icon-App-40x40@2x.png": 80,
            "Icon-App-40x40@3x.png": 120,
            "Icon-App-60x60@2x.png": 120,
            "Icon-App-60x60@3x.png": 180,
            "Icon-App-76x76@1x.png": 76,
            "Icon-App-76x76@2x.png": 152,
            "Icon-App-83.5x83.5@2x.png": 167,
            "Icon-App-1024x1024@1x.png": 1024,
        }
        for filename, dim in ios_sizes.items():
            scaled = master.resize((dim, dim), Image.Resampling.LANCZOS)
            scaled.save(os.path.join(ios_icon_dir, filename), "PNG")
            print(f"Saved iOS Icon: {filename} ({dim}x{dim})")

    print("Completed circular logo generation!")

if __name__ == "__main__":
    generate_and_save()
