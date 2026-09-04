"""Normalize a generated NTI skin to the approved spherical master geometry."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


CANVAS_SIZE = (1254, 1254)
ANTENNA_REGION = (240, 40, 470, 290)


def _purple_mask(image: Image.Image) -> np.ndarray:
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8)
    red = pixels[..., 0].astype(np.int16)
    green = pixels[..., 1].astype(np.int16)
    blue = pixels[..., 2].astype(np.int16)
    alpha = pixels[..., 3]
    return (
        (alpha > 32)
        & (red > 55)
        & (blue > 75)
        & (red > green * 13 // 10)
        & (blue > green * 13 // 10)
    )


def _detect_body_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    body = _purple_mask(image)

    face_band = body[430:671, :]
    _, face_x = np.nonzero(face_band)
    if face_x.size == 0:
        raise ValueError("No purple body pixels detected in the face band")

    center_band = body[240:1230, 560:690]
    center_y, _ = np.nonzero(center_band)
    if center_y.size == 0:
        raise ValueError("No purple body pixels detected in the center band")

    left = int(face_x.min())
    right = int(face_x.max()) + 1
    top = int(center_y.min()) + 240
    bottom = int(center_y.max()) + 241
    return left, top, right, bottom


def normalize_skin(
    input_path: Path,
    master_path: Path,
    output_path: Path,
    preserve_rects: list[tuple[int, int, int, int]],
) -> None:
    source = Image.open(input_path).convert("RGBA")
    master = Image.open(master_path).convert("RGBA")
    if source.size != CANVAS_SIZE or master.size != CANVAS_SIZE:
        raise ValueError("Input and master images must both be 1254 x 1254")

    raw_left, raw_top, raw_right, raw_bottom = _detect_body_bbox(source)
    target_left, target_top, target_right, target_bottom = _detect_body_bbox(master)
    scale_x = (target_right - target_left) / (raw_right - raw_left)
    scale_y = (target_bottom - target_top) / (raw_bottom - raw_top)

    source_without_antenna = source.copy()
    source_without_antenna.paste((0, 0, 0, 0), ANTENNA_REGION)

    inverse_x = 1 / scale_x
    inverse_y = 1 / scale_y
    transformed = source_without_antenna.transform(
        CANVAS_SIZE,
        Image.Transform.AFFINE,
        (
            inverse_x,
            0,
            raw_left - target_left * inverse_x,
            0,
            inverse_y,
            raw_top - target_top * inverse_y,
        ),
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )

    transformed.paste((0, 0, 0, 0), ANTENNA_REGION)
    unclipped_transformed = transformed.copy()

    transformed_pixels = np.asarray(transformed, dtype=np.uint8).copy()
    generated_alpha = transformed_pixels[..., 3]
    master_alpha = np.asarray(master.getchannel("A"), dtype=np.uint8).copy()
    antenna_left, antenna_top, antenna_right, antenna_bottom = ANTENNA_REGION
    master_alpha[antenna_top:antenna_bottom, antenna_left:antenna_right] = 0
    transformed_purple = _purple_mask(transformed)

    # Purple pixels represent NTI's generated body. Clip them to the exact
    # master sphere, while allowing non-purple garments to protrude naturally.
    clipped_purple_alpha = np.minimum(generated_alpha, master_alpha)
    transformed_pixels[..., 3] = np.where(
        transformed_purple,
        clipped_purple_alpha,
        generated_alpha,
    )
    transformed = Image.fromarray(transformed_pixels, mode="RGBA")
    for rect in preserve_rects:
        transformed.alpha_composite(
            unclipped_transformed.crop(rect),
            dest=(rect[0], rect[1]),
        )

    master_body = master.copy()
    master_body.paste((0, 0, 0, 0), ANTENNA_REGION)
    result = Image.alpha_composite(master_body, transformed)

    antenna = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    antenna.paste(master.crop(ANTENNA_REGION), ANTENNA_REGION)
    result = Image.alpha_composite(result, antenna)

    # Discard imperceptible chroma-key remnants left by bicubic resampling.
    result_pixels = np.asarray(result, dtype=np.uint8).copy()
    nearly_transparent = result_pixels[..., 3] <= 4
    result_pixels[nearly_transparent] = (0, 0, 0, 0)
    result = Image.fromarray(result_pixels)
    result.save(output_path)

    print(f"raw_body_bbox={raw_left, raw_top, raw_right, raw_bottom}")
    print(f"target_body_bbox={(target_left, target_top, target_right, target_bottom)}")
    print(f"scale=({scale_x:.6f}, {scale_y:.6f})")
    print(f"wrote={output_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--master", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--preserve-rect",
        action="append",
        default=[],
        metavar="LEFT,TOP,RIGHT,BOTTOM",
    )
    args = parser.parse_args()
    preserve_rects = [
        tuple(int(value) for value in rect.split(","))
        for rect in args.preserve_rect
    ]
    if any(len(rect) != 4 for rect in preserve_rects):
        raise ValueError("Each preserve rectangle needs four coordinates")
    normalize_skin(args.input, args.master, args.output, preserve_rects)


if __name__ == "__main__":
    main()
