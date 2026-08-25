---
name: Proton Remote
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c2c6d6'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#8c909f'
  outline-variant: '#424754'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e6a'
  primary-container: '#4d8eff'
  on-primary-container: '#00285d'
  inverse-primary: '#005ac2'
  secondary: '#b7c8e1'
  on-secondary: '#213145'
  secondary-container: '#3a4a5f'
  on-secondary-container: '#a9bad3'
  tertiary: '#4edea3'
  on-tertiary: '#003824'
  tertiary-container: '#00a572'
  on-tertiary-container: '#00311f'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#004395'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  mono-ui:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  touch-target-min: 48px
  gutter: 16px
  margin-mobile: 20px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

The design system is engineered for precision and high-utility control, targeting power users who need to manage PC environments remotely. The aesthetic is **Modern Corporate**, blending high-performance utility with a refined, dark-centric interface.

The personality is authoritative and reliable. It utilizes a **Modern** approach with subtle hints of **Glassmorphism** for layered depth, ensuring that even in complex control layouts, the primary actions remain distinct. The interface must feel instantaneous, using high-contrast borders and vibrant accents to ensure legibility in low-light environments like home theaters or server rooms.

## Colors

The palette is optimized for OLED screens and low-light usage. 

- **Primary (Tech Blue):** Used for active states, primary toggles, and critical connection indicators.
- **Surface & Background:** The foundation is a deep Charcoal (#0F172A). For layered components like cards or modal sheets, use a slightly lighter slate (#1E293B) to provide structural separation without relying solely on shadows.
- **Accents:** High-visibility Green and Red are reserved for functional status (e.g., "PC Online" vs "Connection Lost"). 
- **Light Mode:** When toggled, the background flips to a clean White (#FFFFFF) with Light Gray surfaces (#F8FAFC), while maintaining the Tech Blue as the primary action color.

## Typography

This design system uses **Inter** for its neutral, systematic, and highly legible characteristics. 

- **Headlines:** Use Bold and Semi-Bold weights to create a strong hierarchy, especially for PC names and active session titles.
- **Labels:** Uppercase labels with slight letter spacing are used for technical categories (e.g., CPU TEMPS, DISK USAGE).
- **Monospace:** **JetBrains Mono** is introduced as a secondary utility font for IP addresses, MAC addresses, and terminal-style output logs to ensure character distinction.

## Layout & Spacing

The layout follows a **Fluid Grid** model optimized for one-handed mobile use. 

- **Tap Targets:** Every interactive element (buttons, toggles, menu items) must maintain a minimum height of 48px.
- **Safe Zones:** High-frequency controls (Mousepad, Media keys) are positioned in the bottom 60% of the screen for ergonomic thumb reach.
- **Grid Tiles:** Remote functions (Power, Sleep, Lock) are arranged in a 2-column or 3-column grid with a 16px gutter.
- **Safe Margins:** A consistent 20px outer margin ensures content does not touch the screen edges, maintaining a "contained" feel.

## Elevation & Depth

This design system avoids heavy, blurred shadows in favor of **Tonal Layers** and **Low-contrast Outlines**. 

- **Level 0 (Background):** Base Charcoal color.
- **Level 1 (Cards/Tiles):** Surface Slate color with a 1px solid border (#334155).
- **Level 2 (Active/Pressed):** Surface color shifts to the Primary Tech Blue or gains a 2px Primary border to indicate selection.
- **Glassmorphism:** Use a 20px backdrop blur on fixed bottom navigation bars or overlays to maintain context of the remote desktop behind the UI.

## Shapes

The shape language is modern and approachable. 

- **Standard Elements:** Buttons, cards, and input fields use a **16px (1rem)** corner radius (`rounded-lg` in this system).
- **Control Pads:** Large interaction areas like the virtual trackpad use the same 16px radius to feel consistent with the overall container.
- **Small Elements:** Status chips and badges use a full pill-shape for distinct visual differentiation from buttons.

## Components

- **Control Tiles:** Square or rectangular grid items. Must include a centered bold line-art icon (24px) and a bottom-aligned `label-sm`.
- **Primary Buttons:** High-contrast Tech Blue background with White text. Height: 56px for main actions.
- **Ghost Buttons:** Transparent background with 1px border. Used for secondary actions like "Settings" or "Advanced Options."
- **Trackpad Area:** Large Surface-level container with a subtle inner-glow or border to define the touch boundaries.
- **Status Indicators:** Small 8px circles using Success/Error colors, placed next to the PC name in the header.
- **Sliders:** Thick 8px tracks for volume and brightness to allow for easy sliding without precise finger placement.
- **Iconography:** Use a consistent 2pt stroke weight. Icons must be monochrome (Light Gray) unless in an active state (Tech Blue).