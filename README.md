# AI Digital Double

Building a 3D model of myself by directing an AI coding agent (Claude Code) that drives Blender, with only a phone camera, a laptop and free tools.

This repo documents every attempt: what was tried, what the AI did, what the result looked like, and why it worked or failed. The final model lives on my portfolio as an interactive piece.

> **Status:** in progress. Stages 1–8 are done (exploration). The final rigged model is next.

## Setup

| | |
|---|---|
| Agent | Claude Code, driving Blender through the Blender MCP server |
| 3D software | Blender 5.2, KeenTools FaceBuilder (add-on), Brush 0.3 (Gaussian splatting) |
| Capture | iPhone 14 Pro Max: photos and a 13-second video |
| Hardware | MacBook with Apple M4, 16 GB RAM |
| Cost | $0 |

## The journey

Full data for each stage is in [`data/timeline.json`](data/timeline.json).

### 1. Head built purely from code
The AI traced my outline in a front and a side photo and built a mesh through it.
**Lesson:** two outlines describe a silhouette, not a face.
![](stages/01-code-built-head/test_threequarter.png)

### 2. KeenTools FaceBuilder from 3 photos
Installed FaceBuilder and drove its face detection from Python. The result had real 3D form, but its shape stayed close to a generic average head.
![](stages/02-facebuilder-photos/portrait_threequarter.png)

### 3. Particle hair
Six iterations of Blender's particle hair. It looked like a knitted cap.
![](stages/03-particle-hair/hair_v6_34.png)

### 4. FaceBuilder from video frames
A custom Swift tool pulled frames from a phone video, and 8 angles were fitted automatically. This was the best face of the early stages.
![](stages/04-facebuilder-video/v_final_threequarter.png)

### 5. On-device photogrammetry (Apple Object Capture)
Got the volume of the hair right, but its surface came out smooth like a beret. The scan was aligned to the face to within 1.4 mm.
![](stages/05-video-photogrammetry/scan_34.png)

### 6. Strand hair grown into the measured volume
About 190,000 strands grown into a hair volume carved from 8 calibrated views. Technically interesting, but the curls didn't look like mine.
![](stages/06-procedural-hair/hair_v2_threequarter.png)

### 7. Full-resolution photo set
Failed because I turned my head instead of the camera moving around me.
![](screenshots/06_photo_scan_flat_mask.png)

### 8. Gaussian splat trained on the laptop
Exported camera positions from Apple's photogrammetry, then trained a splat with Brush on the M4's GPU. This was the first result that truly looked like me, but a splat can't be animated.
![](screenshots/brush_training_viewer.png)

## Lessons so far
1. **Capture beats cleverness.** Most failures traced back to input quality: compressed video, or a moving subject.
2. **Choose the format for the end goal.** Splats give the best likeness but can't be rigged. A rigged mesh is needed for eye tracking and costumes.
3. **Hair is the hardest part.** Procedural hair needs human grooming to read as one specific person's hair.
4. **AI is the operator, not the artist.** The agent installed tools, wrote pipelines and debugged them quickly; judging likeness stayed a human job.

## Repo layout
```
stages/       renders from each attempt
screenshots/  Blender and Brush screenshots
tools/        Swift tools the AI wrote (frame extraction, photogrammetry, camera pose export)
data/         timeline and metrics used for the charts
```

## Next
- Final model: FaceBuilder base, refined likeness, real eyeballs, strand hair, swappable outfits
- Export to GLB, with a three.js viewer where the eyes follow the cursor
- Charts and a write-up on my portfolio
