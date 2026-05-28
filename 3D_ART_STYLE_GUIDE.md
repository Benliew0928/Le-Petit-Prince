# Le Petit Prince: High-Quality Handcrafted 3D Art Style Guide

> **Note for AI Agents:** Read this file carefully before generating, modifying, or texturing any 3D models for this game. Do not default to generic "low-poly" styles. The goal is a premium, handcrafted, storybook-like quality similar to *Zelda: Wind Waker* or *Breath of the Wild*. 

## 1. Core Philosophy: Handcrafted & Premium
The visual identity of this game relies on feeling like a meticulously crafted miniature diorama. Even though the models are technically "low poly," they must never feel cheap, blocky, or unpolished. 

- **Avoid:** Harsh jagged geometry, procedural noise, flat unshaded materials, pure blacks, pure whites, and muddy colors.
- **Embrace:** Soft gradients, deliberate bevels, stylized proportions, harmonious painterly textures, and consistent cel-shaded lighting.

---

## 2. Geometry & Modeling Guidelines
To match the high-quality look of the `player.glb` (Little Prince) model:

- **Soft Edges & Bevels:** Do not leave edges infinitely sharp unless it's a specific stylistic choice (like a blade). Apply slight bevels to corners so they catch specular highlights and rim lighting beautifully.
- **Smooth Shading with Custom Normals:** Use smooth shading. If a sharp transition is needed, use custom split normals rather than detaching geometry. This ensures the toon shader and outline pass wrap smoothly around the model.
- **Silhouette is King:** The silhouette should be readable from a distance. The outline shader amplifies the silhouette, so avoid overly noisy geometry that creates messy outlines.
- **Handcrafted Imperfections:** Perfectly straight lines and perfect spheres feel sterile. Add slight curves, tapers, and organic irregularities to props and architecture to give them a "handmade miniature" feel.

---

## 3. Texturing & Colors
Textures should look like soft watercolor or hand-painted gouache, not sterile hex codes.

- **Painterly Details:** Use baked ambient occlusion (AO) gently multiplied over the base color to add soft depth to crevices.
- **Color Palette:** Use vibrant, cohesive palettes (e.g., pastel sky blues, warm desert oranges, soft greens). Avoid hyper-saturated neons unless for a specific glowing element (like a star). 
- **Gradients:** Use subtle vertical gradients (e.g., darker at the base of a tree trunk, lighter at the top) to ground objects in the world and guide the eye upward.

---

## 4. Shading & Lighting (The Secret Sauce)
The game uses a specific custom shader stack (`toon_ramp.gdshader` + `outline_pass.gdshader`) that you must keep in mind when designing.

### The 3-Step Toon Ramp
The primary shader calculates lighting in three soft steps:
1. **Shadows:** Tinted with a specific color (e.g., dark cool tones like deep blue/purple or dark brown), never just pure black or grey. The transition is slightly smoothed to avoid pixelated jagged edges.
2. **Mid-tones:** The base albedo/texture color.
3. **Highlights:** A subtle brightening toward the light source.

### Specular & Rim Lighting
- **Specular Highlights:** Small, stepped highlights (`specular_size = 0.1`) are used to give materials volume and a slightly tactile, toy-like finish.
- **Rim Lighting:** A warm, soft rim light (`rim_width = 0.4`) wraps around the edges of models **only on the lit side**. This creates a beautiful "halo" effect that pops objects out from the background and makes them feel premium.

### Inverted Hull Outlines
- **Subtle, Colored Outlines:** The game uses an inverted-hull outline pass (`outline_thickness = 0.04`). The color is a dark brown (`vec4(0.15, 0.1, 0.05)`), **not black**. This keeps the scene feeling warm and illustrative rather than like a comic book.

---

## 5. Summary Checklist for AI Agents
When tasked with generating a new model, script, or texture for the game, verify:
- [ ] Does it have organic, handcrafted proportions (not just primitives slapped together)?
- [ ] Are the edges slightly beveled to catch rim lights?
- [ ] Is the texture using hand-painted gradients or soft AO rather than flat uniform colors?
- [ ] Will it look good with a 3-step toon shader and a dark brown outline?
- [ ] Does it feel like a premium miniature belonging in the same universe as the Little Prince?
