[Exercise Moose](../README.md) / Make your own avatar

# Make your own avatar

The flow: **your photo → ChatGPT (cartoon or realistic character) → Kling (exercise videos) → `./convert.sh` → the app.**
You need the source code for `./convert.sh` (see [Build from source](install.md#3-build-from-source)).

## 1. Your character (ChatGPT)

Upload a clear photo of yourself (full body is best, good light, face visible) and use:

> Turn the person in this photo into a 3D character. Full body, standing straight, front view, arms relaxed
> at the sides. Keep my face, hairstyle, beard and skin tone recognisable. Solid pure green background
> #00FF00, no shadows, no floor, character centered with plenty of empty space around it.

Save it as **`raw/character.png`**. Most breaks are seated, so make a sitting version too:

> Same character as in this image, same face, clothes and style. Sitting upright on a simple dark grey
> office chair with no armrests, three-quarter front view, feet flat on the floor, hands resting on the
> thighs. Full body and the whole chair visible. Solid pure green background #00FF00, no desk, no floor,
> no shadows, plenty of empty space around it.

Save it as **`raw/character-seated.png`**. Keep the chair **grey or black, never green**, or the green
removal will cut holes in it. If a face doesn't look like you, ask for a specific fix ("shorter beard",
"rounder glasses") instead of starting over.

## 2. Make it move (Kling Motion Control 3.0, or any image-to-video tool)

**Best results: Kling Motion Control.** Record yourself doing the exercise (phone fixed, whole body
and chair in the shot, about 8 seconds), then give Kling that video plus your character picture:
`character-seated.png` for seated exercises, `character.png` for standing ones.

**Image-to-video instead:** upload the matching picture, paste these **rules first**, then the exercise line:

> Solid pure green background #00FF00, identical in every frame, no shadows, no floor. Camera fixed,
> no zoom, no cuts. The character stays in the exact center and the same size the whole time and never
> moves left, right, forward or back. Keep at least 10% green space on every side so no body part is
> ever cut off. The first and last frame are the same relaxed starting pose so the video loops
> smoothly. Slow, clear movement with correct exercise form. 8 seconds.

Save each clip into `raw/` with the file name from the tables.

**Seated (most breaks), use `character-seated.png`:**

| File (`raw/<name>.mp4`) | Exercise line |
|---|---|
| `neck-stretch` | Sitting tall, the character slowly tilts the head toward the right shoulder, holds, returns to center, then tilts left and holds. |
| `shoulder-rolls` | Sitting tall, the character slowly rolls both shoulders backwards 4 times, then forwards 4 times. |
| `wrist-stretch` | Sitting, the character holds the right arm straight forward palm up and gently pulls the fingers back with the left hand, then switches hands. |
| `torso-twist` | Sitting tall with feet flat, the character turns the upper body to the right holding the backrest, holds, then turns to the left. |
| `seated-leg-raises` | Sitting and holding the edge of the seat, the character straightens the right leg, holds, lowers it, then does the left leg. |
| `seated-march` | Sitting near the front of the chair, the character lifts the knees one at a time in a steady marching rhythm. |
| `seated-cat-cow` | Hands on knees, the character pushes the chest forward and looks up, then rounds the back and looks down, slowly, 3 times. |
| `ankle-circles` | Sitting, the character lifts the right foot and circles the ankle, then does the left foot. |
| `chin-tucks` | Sitting tall and looking ahead, the character pulls the chin straight back, holds, and relaxes, 4 times. |
| `chest-opener` | Sitting tall with hands behind the head, the character opens the elbows wide and squeezes the shoulder blades, holds, relaxes. |
| `seated-side-bend` | Sitting tall, the character reaches the right arm overhead and leans gently to the left, holds, then switches sides. |
| `figure-4` | Sitting, the character puts the right ankle on the left knee and leans forward with a straight back, holds, then switches legs. |

**Standing (one stand-up break every 1–2 hours), use `character.png`:**

| File (`raw/<name>.mp4`) | Exercise line |
|---|---|
| `squats` | The character does 3 slow bodyweight squats: feet shoulder-width, chest up, back straight, hips back, knees over toes, then stands up. |
| `calf-raises` | Hands on hips, the character rises onto the toes, holds 1 second, lowers slowly, 4 times. |
| `wall-pushups` | Side view. A plain light grey wall on the right. The character puts both hands on the wall at shoulder height, bends the elbows to bring the chest close to the wall, pushes back, 3 times, body in a straight line. |
| `hip-stretch` | The character steps one foot back into a small lunge, pushes the hips forward and holds, then steps back to standing. |
| `overhead-stretch` | The character reaches both arms straight up, stretches tall, then lowers the arms slowly out to the sides. |
| `walk` | The character marches in place with arms swinging, smiling. |

**Check the form in every clip.** AI sometimes gets the body movement wrong (bent back, strange knees).
Remake any clip that looks off, because copying bad form can hurt you. Any other name
(e.g. `raw/jumping-jacks.mp4`) becomes a new seated exercise automatically.

_Prompt rules adapted from [dsh-pet](https://github.com/PC2005-cloud/dsh-pet) (MIT)._

## 3. Remove the green background

```bash
./convert.sh        # raw/* -> ~/Library/Application Support/Exercise Moose/
./build.sh          # optional: rebuilds the app icon and menu bar face from your character
```

The app picks new clips up on the next popup. Exercises with a video play it; the rest show your character
picture. As soon as you've added your own media, the app uses only yours, never a mix with the sample.
If you still see green edges, run `SIMILARITY=0.35 ./convert.sh`. If there are holes in the character, try `0.18`.

