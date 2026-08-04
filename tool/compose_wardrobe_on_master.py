"""Place generated wardrobe pixels over an immutable NTI master body."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


CANVAS_SIZE = (1254, 1254)
ANTENNA_REGION = (240, 40, 470, 290)


def _parse_rect(value: str) -> tuple[int, int, int, int]:
    rect = tuple(int(part) for part in value.split(","))
    if len(rect) != 4:
        raise argparse.ArgumentTypeError("A rectangle needs left,top,right,bottom")
    return rect


def compose(
    master_path: Path,
    wardrobe_source_path: Path,
    output_path: Path,
    source_top: int,
    source_bottom: int,
    target_top: int,
    target_bottom: int,
    garment_rects: list[tuple[int, int, int, int]],
    allow_dark_purple_material: bool,
) -> None:
    master = Image.open(master_path).convert("RGBA")
    source = Image.open(wardrobe_source_path).convert("RGBA")
    if master.size != CANVAS_SIZE or source.size != CANVAS_SIZE:
        raise ValueError("Master and wardrobe source must both be 1254 x 1254")

    scale_y = (target_bottom - target_top) / (source_bottom - source_top)
    inverse_y = 1 / scale_y
    transformed = source.transform(
        CANVAS_SIZE,
        Image.Transform.AFFINE,
        (1, 0, 0, 0, inverse_y, source_top - target_top * inverse_y),
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    transformed.paste((0, 0, 0, 0), ANTENNA_REGION)

    master_pixels = np.asarray(master, dtype=np.uint8)
    source_pixels = np.asarray(transformed, dtype=np.uint8)
    master_rgb = master_pixels[..., :3].astype(np.int16)
    source_rgb = source_pixels[..., :3].astype(np.int16)
    source_alpha = source_pixels[..., 3]

    region = np.zeros((CANVAS_SIZE[1], CANVAS_SIZE[0]), dtype=bool)
    for left, top, right, bottom in garment_rects:
        region[top:bottom, left:right] = True

    red = source_rgb[..., 0]
    green = source_rgb[..., 1]
    blue = source_rgb[..., 2]
    maximum = source_rgb.max(axis=2)
    minimum = source_rgb.min(axis=2)
    purple_body = (
        (red > green * 13 // 10)
        & (blue > green * 13 // 10)
        & (blue > 60)
    )
    neon_cyan = (blue > 145) & (green > 105) & (red < 125)
    neon_magenta = (red > 175) & (blue > 165) & (green < 145)
    bright_neon = neon_cyan | neon_magenta
    neutral_material = ((maximum - minimum) < 58) | (maximum < 55)
    dark_surface = maximum < 165

    difference = np.linalg.norm(master_rgb - source_rgb, axis=2)
    opaque_source = source_alpha > 8
    inside_master = master_pixels[..., 3] > 8
    material = (~purple_body) | bright_neon
    if allow_dark_purple_material:
        material |= dark_surface & (difference > 110)
    inside_candidate = (
        region
        & opaque_source
        & inside_master
        & material
        & (difference > 55)
    )
    outside_candidate = (
        region
        & opaque_source
        & ~inside_master
        & ((~purple_body) | neutral_material | bright_neon)
    )

    # Expand only the interior garment mask by one pixel so antialiased edges
    # remain smooth without introducing generated body pixels outside the sphere.
    interior_image = Image.fromarray((inside_candidate * 255).astype(np.uint8))
    expanded_interior = np.asarray(
        interior_image.filter(ImageFilter.MaxFilter(3)),
        dtype=np.uint8,
    ) > 0
    clothing_mask = (expanded_interior & region & inside_master) | outside_candidate

    clothing_pixels = source_pixels.copy()
    clothing_pixels[..., 3] = np.where(
        clothing_mask,
        source_alpha,
        0,
    ).astype(np.uint8)
    clothing = Image.fromarray(clothing_pixels)

    result = Image.alpha_composite(master, clothing)
    result.save(output_path)

    print(f"vertical_scale={scale_y:.6f}")
    print(f"wardrobe_pixels={int(clothing_mask.sum())}")
    print(f"wrote={output_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--master", type=Path, required=True)
    parser.add_argument("--wardrobe-source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--source-top", type=int, required=True)
    parser.add_argument("--source-bottom", type=int, required=True)
    parser.add_argument("--target-top", type=int, required=True)
    parser.add_argument("--target-bottom", type=int, required=True)
    parser.add_argument(
        "--garment-rect",
        action="append",
        type=_parse_rect,
        default=[],
        required=True,
    )
    parser.add_argument("--allow-dark-purple-material", action="store_true")
    args = parser.parse_args()
    compose(
        args.master,
        args.wardrobe_source,
        args.output,
        args.source_top,
        args.source_bottom,
        args.target_top,
        args.target_bottom,
        args.garment_rect,
        args.allow_dark_purple_material,
    )


if __name__ == "__main__":
    main()
