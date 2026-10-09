# AI Digital Double

**Can one person with a phone, a laptop and an AI agent build a 3D model of their own head that looks back at you? Yes. Here's every step, including the parts that failed.**

I directed an AI coding agent (Claude Code) to drive Blender and a handful of free tools. My inputs were phone photos, a 13-second video and my own review notes. The result runs in a browser, and its eyes follow your cursor.

**[See it live on my portfolio →](https://kmsmohamedansar.github.io/#digital-double)**

| Front | Three-quarter | Profile |
|---|---|---|
| ![](final/final_front.png) | ![](final/final_threequarter.png) | ![](final/final_profile.png) |

## At a glance

| | |
|---|---|
| Agent | Claude Code, driving Blender live through the Blender MCP server |
| 3D tools | Blender 5.2, KeenTools FaceBuilder, Apple Object Capture, Brush 0.3 (Gaussian splatting), three.js |
| Code the agent wrote | Python inside Blender (mesh, hair, texture and shader work), 3 Swift tools, a chart generator, the web viewer |
| Capture | iPhone 14 Pro Max: photos and a 13-second video |
| Hardware | Laptop with Apple M4, 16 GB RAM |
| Cost | $0 |
| Time | About 6 hours across 12 stages, including 4 rounds of my review |
| Output | An 8 MB GLB (head, separate eyeballs, hair cards) in a web viewer where the eyes follow the cursor |

## How it works

![Pipeline](charts/pipeline.svg)

The loop that did the real work:

```mermaid
flowchart LR
    A[I describe what's wrong<br/>in plain English] --> B[Claude Code plans<br/>and writes Python]
    B --> C[Runs it live in Blender<br/>via MCP]
    C --> D[Renders the result<br/>and looks at it]
    D -->|not right yet| B
    D -->|looks right| E[Shows me renders]
    E -->|I spot a problem| A
    E -->|approved| F[Bake, export GLB,<br/>update this repo]
```

What a single fix looks like, for example "there's hair in my ears":

```mermaid
sequenceDiagram
    participant Me
    participant Agent as Claude Code
    participant B as Blender (MCP)
    Me->>Agent: hair is in the ears and below them
    Agent->>B: measure head width at each height
    B-->>Agent: skull 57 mm, ears stick out to 63-71 mm
    Agent->>B: trace each ear's outline from the mesh
    Agent->>B: regrow 160k strands, reject any within 2.5 mm of an ear
    Agent->>B: render both profiles
    B-->>Agent: images
    Agent->>Me: before/after renders
```

## Charts

![Timeline](charts/timeline.svg)

![Where the time went](charts/time.svg)

![Outcomes](charts/outcomes.svg)

## The journey

Full data for every stage, including inputs, tools, method, result and lesson, is in [`data/timeline.json`](data/timeline.json). The charts above are generated from that file by [`tools/make_charts.py`](tools/make_charts.py).

### 1. Head built purely from code: dead end
The agent traced my outline in a front and a side photo and built a mesh through it.
**Lesson:** two outlines describe a silhouette, not a face.
![](stages/01-code-built-head/test_threequarter.png)

### 2. KeenTools FaceBuilder from 3 photos: partial
The agent installed FaceBuilder from a local folder and drove its face detection from Python. The result had real 3D form, but its shape stayed close to a generic average head.
![](stages/02-facebuilder-photos/portrait_threequarter.png)

### 3. Particle hair: dead end
Six iterations of Blender's particle hair. It looked like a knitted cap. One bug: Blender silently reset the hair length to 4 m whenever another setting changed.
![](stages/03-particle-hair/hair_v6_34.png)

### 4. FaceBuilder from video frames: partial
A Swift tool written by the agent pulled frames from a phone video, and FaceBuilder fitted 8 angles automatically. This became the base of the final model.
![](stages/04-facebuilder-video/v_final_threequarter.png)

### 5. On-device photogrammetry (Apple Object Capture): useful as measurement
Got the volume of my hair right, but its surface came out smooth like a beret. The scan was aligned to the face to within 1.4 mm.
![](stages/05-video-photogrammetry/scan_34.png)

### 6. Strand hair grown into the measured volume: dead end
About 190,000 strands grown into a hair volume carved from 8 calibrated views. Technically interesting, but it read as tight rope curls, and a masking rule left my temples bald.
![](stages/06-procedural-hair/hair_v2_threequarter.png)

### 7. Full-resolution photo set: dead end
Failed because I turned my head instead of the camera moving around me, which produced a flat mask.
![](screenshots/06_photo_scan_flat_mask.png)

### 8. Gaussian splat trained on the laptop: best likeness, wrong format
The agent exported camera positions from Apple's photogrammetry engine and trained a splat with Brush on the M4's GPU. This was the first result that unmistakably looked like me. But a splat can't be animated, so it can't drive eye tracking or wear outfits.
![](screenshots/08_splat_web_viewer_front.jpg)

### 9. Final model: real eyes, hair, web export: shipped
- **Eyes:** almond-shaped eye openings cut to match the photo texture, eyelid edges smoothed, and separate eyeballs added behind them with a procedural brown iris and a wet coating. Both eyeballs aim at a shared target. It took 9 iterations to keep the whites inside the lids.
- **Hair and lashes:** regrown from my real hairline as detected in the texture, plus subtle eyelashes.
- **Web export:** every material baked to image textures, 121,000 hair strands converted into 6,300 hair cards, and the result exported as a GLB.
- **Viewer:** a three.js page where the head turns slightly toward the cursor and the eyes do the rest.

| Eyes, first attempt | Eyes, final | Eyes following a target |
|---|---|---|
| ![](stages/09-final-model/eyes/eyes_v1.png) | ![](stages/09-final-model/eyes_v9_34.png) | ![](stages/09-final-model/eyes/look_left.png) |

### 10. Fixes from my own review: shipped
After looking at the model in Blender I flagged three things. The agent then:
- **Eyes looked sideways:** re-centred each eyeball on its measured eyelid opening (they were 2–3 mm off).
- **Receding temples:** found zero hair roots in the temple corners between 38 and 62 mm above the eyes, and added about 3,000 there, plus short sideburns.
- **Neck and collar smear:** repainted the neck with my sampled skin tone, blended the seam in the shader, and modelled a crew-neck t-shirt fitted to the neck's measured shape.

| Before | After |
|---|---|
| ![](stages/10-feedback-fixes/shirt_front.png) | ![](final/final_front.png) |

### 11. Second review: shipped
I flagged stray hair below the ears, eyes still looking off-centre, and an artificial look overall. The agent then:
- **Eyes:** measured my real eye size in the photo texture, recut the openings to 22 × 8 mm, and re-centred both eyeballs on them. They now look straight ahead, with no white outside the lids.
- **Hair:** removed every hair root beside and below the ears.
- **Neck:** restored the original beard where an earlier repaint had left a flat skin-coloured block. It found the cause by casting a ray from the camera to the exact texture pixel.
- **Clothes:** an olive polo with a folded collar, placket and buttons, picked to suit warm brown skin.
- **Skin:** pore detail and subsurface scattering, so it reads less like plastic.

| Eyes before | Eyes after |
|---|---|
| ![](stages/11-second-review/eyecheck.png) | ![](stages/11-second-review/eyecheck4.png) |

### 12. Head-only bust, hair rebuilt: shipped
After a third review I dropped the shirt (it looked worse than no shirt) and asked for the hair to be fixed in one go. The agent then:
- **Neck:** capped it with a clean flat cut, which removed a ragged edge that showed as a glitch.
- **Ears:** traced each ear's real outline from the mesh. Hair now grows only above and behind it, and any strand within 2.5 mm of an ear is rejected.
- **Temples:** replaced the long, comb-like strands with short, flat hair combed back, with a soft, graduated hairline.

| Temple before | Temple after |
|---|---|
| ![](stages/12-head-only-hair/temple_closeL.png) | ![](stages/12-head-only-hair/temple3_L.png) |

## Lessons
1. **Capture beats cleverness.** Most failures traced back to input quality: compressed video, or a moving subject.
2. **Choose the format for the end goal.** The splat gave the best likeness but can't be animated. A mesh with separate eyes can.
3. **Hair is the hardest part.** Procedural hair needs grooming to read as one specific person's hair.
4. **Eyes are where likeness lives.** Painted-on eyes made every version look dead. Real eyeballs changed it most.
5. **Review like an art director.** The agent's measurements were right, but "looks bald" and "eyes look sideways" only came from looking.
6. **AI is the operator, not the artist.** The agent installed tools, wrote pipelines in Python and Swift, and debugged them quickly. Judging whether it looked like me stayed a human job.

## Honest limits
- **Quality:** stylized-realistic, not film quality. The face shape comes from a morphable model fitted to 8 video frames, so fine detail is approximate.
- **Eyes:** no blinking or eyelid movement yet.
- **Hair:** procedural, not groomed by hand.

## Try it locally
```bash
cd web && python3 -m http.server 8000
```
Then open http://localhost:8000. The viewer loads `digital_double.glb` and three.js from a CDN.

## Screenshots: the tools in action

### Blender, driven by the agent
| | |
|---|---|
| ![](screenshots/01_blender_connected_default_scene.png) Blender connected to Claude through MCP: the starting scene | ![](screenshots/02_reference_photos_aligned.png) Reference photos aligned to real-world scale |
| ![](screenshots/18_head_mesh_topology.png) The head mesh: 18k vertices of clean, animatable topology | ![](screenshots/21_face_texture_uv.png) The face texture and its UV layout, with every repair painted in by code |
| ![](screenshots/20_eye_shader_nodes.png) The eye shader: a procedural iris, pupil and wet coat, built node by node | ![](screenshots/12_skin_shader_nodes.png) The skin shader: tone correction, pores, subsurface scattering |
| ![](screenshots/19_ear_outline_traced.png) The ear outline traced from the mesh (red), used to keep hair out of the ears | ![](screenshots/17_blender_final_hair_selected.png) The final hair: 160k strands as Blender hair curves |

### KeenTools FaceBuilder
| | |
|---|---|
| ![](screenshots/10_facebuilder_8_views_and_cameras.png) 8 video frames solved, with a camera placed for each view | ![](stages/04-facebuilder-video/input_video_frames.png) The video frames it was fitted to |

### Photogrammetry and Gaussian splats
| | |
|---|---|
| ![](screenshots/04_video_scan_imported.png) Apple Object Capture scan from 128 video frames | ![](screenshots/05_hair_volume_from_8_views.png) Hair volume carved from 8 calibrated views |
| ![](screenshots/06_photo_scan_flat_mask.png) A failed capture: turning my head instead of the camera gave a flat mask | ![](screenshots/brush_training_viewer.png) Brush training a Gaussian splat on the M4 GPU |
| ![](screenshots/07_splat_as_points_in_blender.png) The splat as raw points in Blender | ![](screenshots/08_splat_web_viewer_front.jpg) The splat in a web viewer: the best likeness, but it can't be animated |

### Hair, from bad to better
| | |
|---|---|
| ![](screenshots/03_particle_hair_viewport.png) Particle hair: looked like a knitted cap | ![](screenshots/11_strand_hair_viewport.png) First strand hair: rope-like curls |
| ![](stages/12-head-only-hair/temple_closeL.png) Temples before: comb-teeth strands | ![](stages/12-head-only-hair/temple3_L.png) Temples after: short, flat, soft hairline |

### In the browser
| | |
|---|---|
| ![](screenshots/13_web_viewer_glb.jpg) The final GLB in a three.js viewer, looking straight ahead | ![](screenshots/15_eyes_following_cursor_left.jpg) Head and eyes following the cursor |
| ![](screenshots/16_portfolio_page.jpg) On the portfolio | ![](screenshots/22_portfolio_how_it_was_made.jpg) The "How it was made" section on the portfolio |
| ![](screenshots/23_portfolio_stage_cards.jpg) Stage cards on the portfolio | ![](screenshots/09_splat_web_viewer_orbit.jpg) The splat viewer, orbited |

## Repo layout
```
final/        hero renders of the finished model
web/          the GLB and a standalone three.js viewer
stages/       renders from each attempt
screenshots/  Blender, Brush and browser screenshots
charts/       SVG charts generated from data/timeline.json
tools/        Swift tools (frame extraction, photogrammetry, camera poses) and the chart script
data/         timeline.json: one entry per stage
```

## What's next
- Blinks and simple expressions, using FaceBuilder's built-in face shapes
- Swappable outfits
- Hair groomed by hand in Blender's sculpt mode
