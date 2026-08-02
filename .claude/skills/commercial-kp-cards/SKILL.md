---
name: commercial-kp-cards
description: Use when building or editing pages under commercial/ (Midnight Collective's "Услуги и цены" КП / commercial-proposal pages) — building a new theme page, adding a Figma КП section to an existing page, editing pricing-card content or style, or fixing card spacing/typography. Covers site architecture, the locked .kp-card CSS template, and the Figma→HTML content workflow.
---

# Commercial КП (pricing card) pages — build guide

Midnight Collective's commercial-offer pages: pricing cards per service, organized by theme,
one page per theme, linked from a menu page. Source of truth for CONTENT is Figma; source of
truth for VISUAL STYLE is this file (Figma's own raw export values are not always what's
actually applied — see Gotchas below).

## Site architecture

- `commercial/index.html` — a MENU page. Lists every theme as a row (`.theme-row`): built themes
  are a real `<a href="commercial/<slug>/">` link with status "Готово"; unbuilt themes are plain
  `<span>` (no link) with status "Скоро". This page has NO pricing cards on it.
- `commercial/<slug>/index.html` — one page per THEME. A theme can bundle multiple Figma frames
  that are about the same topic (e.g. `commercial/reels/` contains both "КП - 1 - Reels" AND
  "КП - 2 - Reels" as two `<section class="kp-section">` blocks on one page — don't split every
  Figma frame into its own page, group by topic).
- No CTA button ("Обсудить проект") on theme pages — removed on purpose. These read as a pure
  deck/presentation, not a landing page with a conversion action. Footer (phone/email/logo/privacy
  link) stays.
- Subpages are one directory deeper than the menu page, so font `src:` paths are `../../fonts/...`
  (not `../fonts/...` like the menu page and the rest of the site).
- Figma source: file "Midnight Collective" → page "КП | Шаблон". Node ids for all 11 frames and
  their planned theme/slug mapping live in the project's auto-memory (`commercial_page_status`
  memory file) — check there, or ask the user for the Figma link if it's not available.
- Local preview: `python3 -m http.server 8934 --bind 127.0.0.1` from the repo root
  (`/Users/egorkurakin/midnight-collective`), then open `http://127.0.0.1:8934/commercial/...` —
  the claude-in-chrome browser extension can't navigate `file://` URLs directly, needs an http
  server running. Browsers cache `.woff2` font files aggressively — if a font-file edit doesn't
  seem to show up, hard-refresh (Cmd+Shift+R) before assuming the fix didn't work.

## Workflow

1. Fetch the relevant Figma node with `mcp__figma-dev-mode-mcp-server__get_design_context`.
2. Pull CONTENT 1:1 from the response (titles, bullet text, prices, terms, durations) — don't
   paraphrase or "clean up" copy.
3. Build the HTML using the exact class structure and CSS below — don't invent new spacing/sizing
   from the Figma export's raw Tailwind values, use what's documented here.
4. Do ONE section/card-group at a time, screenshot it in the browser, and get explicit user
   confirmation before moving to the next one. Don't batch multiple sections ahead of confirmation
   — this burned a rollback once already.
5. If the user flags a visual mismatch after you've already matched the exported JSX class names,
   don't just re-check the code — ask them to open Figma's own Typography/Appearance/Stroke
   inspector panel on that exact node and read the real applied values from there (see Gotchas).

## Card HTML structure

Every pricing card has 4 parts: title+subtitle, a body with one or two bullet-list groups, and a
price/terms/duration foot block. A `.dashed` variant exists for optional/add-on services.

```html
<div class="kp-card">                              <!-- add "dashed" class for optional/add-on cards -->
  <!-- dashed cards ONLY: insert this svg right after the opening div -->
  <svg class="kp-card-dash-border"><rect x="0" y="0" width="100%" height="100%" rx="14.3" ry="14.3" fill="none" stroke="#000" stroke-width="1.4" stroke-dasharray="10 10"/></svg>

  <div class="kp-card-title">Монтаж Reels</div>     <!-- service name -->
  <div class="kp-card-sub">Экспресс (до 30 сек)</div> <!-- variant/tier name, same font-size as title -->

  <div class="kp-card-body">
    <ul class="kp-card-list">                        <!-- main checklist -->
      <li>Исходный материал: до 10 минут</li>
      <li class="carry">Всё из базового пакета, плюс:</li>  <!-- use .carry for "everything from X, plus:" lines -->
      ...
    </ul>
    <ul class="kp-card-list extra">                   <!-- OPTIONAL second group: iteration count, -->
      <li>1 итерация правок</li>                       <!-- storage duration, add-on prices, tech notes -->
    </ul>
  </div>

  <div class="kp-card-foot">
    <div class="kp-terms">100% предоплата</div>
    <div class="kp-price">5 000 ₽</div>
    <div class="kp-duration">Срок: 1-2 дня</div>
  </div>
</div>
```

The `.extra` second `<ul>` is optional — only add it if Figma's frame actually shows a paragraph
break (bigger gap) before a trailing group of meta items (iterations/storage/addon-price/notes).
Not every card has one; some cards are one flat list.

IMPORTANT — row alignment rule: whenever a row of cards mixes some with a real `.kp-card-sub` and
some without one (Figma sometimes gives one card just a single-line title, e.g. "Мерч" next to
"Логотип / Типографический"), the checklist below MUST start at the same vertical position across
every card in that row — this matters more than matching Figma's literal single-line title, and the
user has flagged misaligned checklists as a real bug, not a nitpick. Fix: give every card exactly 2
header lines regardless of Figma content — for a card with no real subtitle, add an invisible
placeholder second line instead of omitting `.kp-card-sub`:
```html
<div class="kp-card-title">Мерч</div>
<div class="kp-card-sub">&nbsp;</div>
```
With this, `.kp-card-title` and `.kp-card-sub` keep their normal CSS (no special-casing, no `:has()`
trick needed — a page-local `margin-bottom:20px` on `.kp-card-title` alone is ONLY correct if every
single card on that page has no sub at all, e.g. `commercial/motion/`; the moment a page mixes both,
use the `&nbsp;` placeholder approach instead, it's simpler and guarantees alignment across the row).

On `commercial/bots/`, Figma's own grouping put "N итераций правок" / "N дней поддержки" inside the
SAME first group as the main checklist (no 24px break before them in the raw export) — but the user
asked to pull them into their own `.extra` group anyway, matching the house convention used
everywhere else on the site (iterations/support/storage as their own visually-separated group). When
a card's trailing meta lines (iterations, support days, storage) read as glued to the main list, split
them into their own `<ul class="kp-card-list extra">` even if Figma's raw grouping didn't do that —
this is now the expected default, not a one-off.

Some cards have MORE than 2 groups — e.g. a card can open with a single intro paragraph, then two
labeled subgroups each with their own underlined header (`.carry`) and item list, all inside one
card (seen on `commercial/branding/`'s "Макеты носителей" card: intro line, then "Физические
носители" + 6 items, then "Диджитал носители" + 3 items — 3 stacked `<ul class="kp-card-list">`,
the 2nd and 3rd both `extra` for the 24px paragraph gaps, each starting with a `.carry` header li).
Also: not every card has a `.kp-terms` line — some (like that same card) just show `.kp-price` +
`.kp-duration` with no payment-terms line above it. Follow whatever Figma's frame actually shows,
these two-part/three-part patterns aren't universal.

A standalone note paragraph inside a card (e.g. "3D-интеграция — от 15 000 ₽ (точная цена зависит
от сложности...)" on the "Графика для мероприятий" card) is NOT a specially-styled block — it's
just a THIRD `<ul class="kp-card-list extra">` group with one `<li>`, same gray/14px/Inter Regular
style as every other list item, 24px paragraph gap like any other group. An earlier draft wrongly
invented a separate `.kp-card-note` class for this (smaller font, darker gray, border-top divider
line) — that was wrong, Figma has no divider line and no color/size change here. Don't reintroduce
`.kp-card-note`; if you see it in an older page's CSS it's a bug to fix, not a pattern to copy.

## Locked CSS (do not restyle without the user explicitly asking)

```css
/* PRICING GRID */
.kp-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr)); gap: 16px; }
.kp-card { position: relative; border: 1px solid #000; border-radius: 15px; padding: 30px; display: flex; flex-direction: column; min-height: 656px; }
.kp-card.dashed { border: none; }
.kp-card-dash-border { position: absolute; inset: 0; width: 100%; height: 100%; pointer-events: none; }
.kp-card-title { font-size: 18px; font-weight: 500; letter-spacing: -0.02em; line-height: 1.1; }
.kp-card-sub { font-size: 18px; font-weight: 400; color: #b3b3b3; line-height: 1.1; margin-bottom: 20px; }
.kp-card-body { flex: 1; display: flex; flex-direction: column; }
.kp-card-list { list-style: none; font-size: 14px; line-height: 1.2; letter-spacing: 0.01em; color: #b3b3b3; }
.kp-card-list li { margin-bottom: 10px; }
.kp-card-list li:last-child { margin-bottom: 0; }
.kp-card-list li.carry { text-decoration: underline; font-weight: 500; }
.kp-card-list.extra { margin-top: 24px; }
.kp-card-foot { margin-top: 24px; }
.kp-terms { font-size: 14px; font-weight: 500; line-height: 1.2; color: #000; letter-spacing: 0.01em; margin-bottom: 4px; }
.kp-price { font-size: 14px; font-weight: 500; line-height: 1.2; letter-spacing: 0.01em; }
.kp-price-note { font-size: 14px; font-weight: 500; color: #999; }  /* e.g. gray "1 рилс: 3 500 ₽" note after a bulk price */
.kp-duration { font-size: 14px; font-weight: 500; line-height: 1.2; color: #000; letter-spacing: 0.01em; margin-top: 12px; }

/* SECTION HEAD (repeats per theme page, once per Figma frame bundled into that page) */
.kp-section { padding: 96px 48px 0; }
.kp-section:first-of-type { padding-top: 48px; }
.kp-head { display: flex; justify-content: space-between; align-items: baseline; gap: 24px; margin-bottom: 40px; flex-wrap: wrap; }
.kp-title { font-size: 56px; font-weight: 500; letter-spacing: -0.06em; line-height: 1.05; }
.kp-kicker { font-family: 'Roboto Mono', monospace; font-size: 12px; font-weight: 400; letter-spacing: 0; text-transform: uppercase; color: #666; white-space: nowrap; }
```

Section markup pattern:

```html
<section class="kp-section">
  <div class="kp-head">
    <h2 class="kp-title">Монтаж Reels — Поштучно</h2>
    <span class="kp-kicker">Услуги и цены</span>
  </div>
  <div class="kp-grid">
    <!-- kp-card × N -->
  </div>
</section>
```

Fonts: `Inter` (300/400/500/600, self-hosted woff2) + `Roboto Mono` (400) — same files as the rest
of the site, loaded via `@font-face` at the top of every page. Never use Figma's raw `Suisse Intl`
font-family — see Gotchas, it doesn't actually mean what it looks like it means.

## USP banner between sections on the same theme page

When a theme page bundles multiple sections that are variants of the same service (e.g.
"поштучно" vs "пакеты на месяц" pricing), a divider banner can go between them to pitch the
better deal. This is NOT from Figma — it's original copy, styled to match the homepage's own
`.services` block pattern (30%-label + text grid, no color, just borders):

```html
<div class="kp-usp">
  <span class="kp-usp-label">УТП</span>
  <p class="kp-usp-text">Нужно несколько Reels в месяц? Пакет на месяц выгоднее, чем заказывать монтаж поштучно — цена за один ролик ниже, а условия комфортнее.</p>
</div>
```

```css
.kp-usp { display: grid; grid-template-columns: 30% 1fr; gap: 24px; align-items: baseline; padding: 56px 48px; margin-top: 96px; }
.kp-usp-label { visibility: hidden; }  /* label column kept for layout/position only — no border lines, no visible "УТП" tag; user asked both removed but text position preserved */
.kp-usp-text { font-size: 32px; font-weight: 500; letter-spacing: -0.04em; line-height: 1.25; max-width: 720px; }
/* mobile: grid-template-columns: 1fr; gap: 12px; padding: 32px 20px; margin-top: 56px; .kp-usp-text{font-size:22px} */
```

Only add this between sections that genuinely have a per-unit-vs-bulk (or similar) relationship
worth pitching — don't add a banner between every pair of sections by default.

This split-with-a-USP-banner pattern isn't limited to sections that were already two separate Figma
frames (like Reels). The user has also asked to RESTRUCTURE a single Figma frame this way after the
fact — e.g. `commercial/design/` originally had 6 cards in one row per Figma, but the 6th (a dashed
"point request" card, cheaper/simpler than the other 5) got pulled into its own section + USP banner
once the row became visually crowded. Watch for cards that are a clear outlier in a row (different
pricing model, a "no full rebuild" caveat, dashed/optional) — that's a signal it may read better
split out like this, even if Figma drew it as one frame. Don't do this preemptively though — only
when the user flags the row as crowded/off or asks for it directly.

Also: when a page's own copy (like `.kp-head-note`) references OTHER services by name (e.g. Дизайн's
note originally said "...по созданию фирменного стиля"), check whether that thing now has its own
dedicated page — if so, the copy is probably stale/wrong and needs rewriting to describe THIS page's
actual scope instead of what made sense back when everything was one undifferentiated Figma deck.

## Reserving space for a card the user will add later

Sometimes the user wants a section built for N cards but only has content for fewer right now,
planning to add the rest later (e.g. "Поддержка бизнеса" on `commercial/design/` — user wants it to
look like a 2-card row with only the left card filled in for now). Don't let a single card stretch
to full width via the normal `auto-fit` grid — force the intended column count instead:
```css
.kp-grid.two-col { grid-template-columns: repeat(2, 1fr); }
/* mobile override alongside the existing .kp-grid mobile rule: */
.kp-grid, .kp-grid.two-col { grid-template-columns: 1fr; }
```
```html
<div class="kp-grid two-col">
  <div class="kp-card">...</div>
  <!-- right slot intentionally left empty, to be filled in later -->
</div>
```
Also: a section's `.kp-head` doesn't always need a right-side element — if the user asks to remove
the "Услуги и цены" kicker from a specific section, just drop the `<span class="kp-kicker">` entirely
rather than replacing it with something else (don't assume every section needs a right-side element).

## kp-head right slot: kicker vs. a real note

The right side of `.kp-head` (next to the big section title) is normally the small `.kp-kicker`
("Услуги и цены" label). But on some Figma frames that slot is used for a real sentence instead
(e.g. the YouTube section's volume-discount note) — Figma REPLACES the kicker with that text for
that one frame, it doesn't show both. When that happens, drop `.kp-kicker` for that section and put
the note in its place using `.kp-head-note` (right-aligned, wraps to multiple lines):

```css
.kp-head { display: flex; justify-content: space-between; align-items: flex-end; gap: 24px; margin-bottom: 40px; flex-wrap: wrap; }
.kp-head-note { font-size: 17px; font-weight: 500; color: #151515; letter-spacing: -0.03em; text-align: right; width: 490px; flex-shrink: 0; line-height: 0.9; transform: translateY(-10px); }
```
The `transform: translateY(-10px)` is a manual nudge: `align-items: flex-end` on `.kp-head` gets the
note block CLOSE to bottom-aligned with the title but not pixel-exact (line-box metrics leave a bit
of residual whitespace under the text). The user asked specifically for the note's second line to
sit level with the title's bottom edge; this nudge is what achieved that visually — don't remove it
thinking it's redundant with `flex-end`, both are needed.

IMPORTANT: font-size is 17px, NOT Figma's literal 24px. Figma's frame is 1920px wide; our page's
`.kp-title` is deliberately BIGGER than Figma's literal title size (56px vs Figma's 48px — an
established, approved sitewide deviation, see the top-level "Visual styling = site's own system, NOT
Figma's raw pixel values" rule). Copying the note's literal 24px onto our narrower, bigger-titled
page made it read visually oversized relative to the title compared to how it reads in Figma — sizes
need to be scaled to how the composition LOOKS in Figma relative to the title, not copied as literal
px. User asked for roughly 30% smaller than the literal Figma value to fix this — that's how 17px was
reached (24 × 0.7 ≈ 17, width scaled proportionally 700 × 0.7 ≈ 490). If a future note/aside text
looks "off" vs Figma despite matching literal px values, check whether the surrounding elements
(title, etc.) were deliberately resized off-Figma first — the note needs to scale WITH those, not
against them.
Notes, all confirmed against Figma's Typography inspector on the actual text node:
- `width` + `flex-shrink: 0` (not `max-width`) — `.kp-head` is a flex row with the big title as the
  other item, and without a fixed width + no-shrink, the note gets squeezed by the title's natural
  width and wraps to 3 lines instead of Figma's 2.
- Color `#151515` (near-black, NOT the gray `#666` used elsewhere for secondary text) — first attempt
  wrongly used small gray 16px text here, that's the wrong slot's styling (`.kp-section-note`, a
  DIFFERENT class for a different placement, looks like that).
- `line-height: 0.9` and `letter-spacing: -0.03em` (90% / -3%, both tighter than the first-attempt
  guesses of 1.15 / -0.02em) — read directly off Figma's Typography panel, don't re-guess these.
- `.kp-head`'s `align-items` must be `flex-end`, not `baseline` — Figma positions this 2-line note
  block so its bottom edge sits level with the bottom of the (shorter, 1-line) title, not aligned by
  text baseline.
```html
<div class="kp-head">
  <h2 class="kp-title">Монтаж под YouTube</h2>
  <p class="kp-head-note">При заказе от 3 видео в месяц предоставляется скидка 20% на монтаж (независимо от выбранного пакета).</p>
</div>
```

Don't default to always using `.kp-kicker` — check whether Figma's top-right slot for that specific
frame holds the usual "Услуги и цены" label or something else, and match what's actually there.

## Content abbreviation rule

Every form of "дополнительн-" (дополнительный/дополнительная/дополнительных/дополнительно etc.) in
card copy gets shortened to "доп." — e.g. "Дополнительный спикер" → "Доп. спикер", "(дополнительная
итерация — 5 000 ₽)" → "(доп. итерация — 5 000 ₽)", "дополнительных макетов" → "доп. макетов". This
applies retroactively to already-built pages too, not just new ones — when adding a new section,
grep the whole `commercial/` tree for "дополнительн" (case-insensitive) and fix every hit, not just
the current page's.

## Gotchas (read before assuming a Figma export value is correct)

- **`Suisse_Intl:*` JSX tags are misleading.** `get_design_context`'s exported code tags some text
  nodes `font-['Suisse_Intl:Book']` etc. — that's a leftover Figma text-STYLE name, not necessarily
  the literal applied font. On this project it turned out the real applied font for those nodes was
  **Inter Medium** (confirmed via Figma's own Typography inspector panel, not the exported code).
  If a visual mismatch is reported after already matching the exported tags, don't just re-check the
  JSX — ask for a screenshot of Figma's Typography panel on that exact node.
- **The checklist is not one flat list.** Figma's layer inspector showed 3 distinct spacing values:
  (a) line-height WITHIN a single wrapped bullet = 120% (tight), (b) gap BETWEEN bullets in the same
  group = 10px, (c) gap BETWEEN the main checklist and a trailing "meta" group (iterations/storage/
  addon prices) = 24px, a real paragraph break. This is why cards use two `<ul>`s (see above), not one.
- **Dashed borders**: plain CSS `border-style:dashed` auto-spaces dashes and looks wrong vs Figma's
  explicit Dash 10 / Gap 10 stroke setting. Use the inline SVG rect overlay shown in the card markup
  above instead — gives exact dash/gap control. Stroke-width is 1.4 (not 1) because a 1px SVG stroke
  visibly thickens on the curved corners (antialiasing artifact on curved vs straight path segments) —
  bumping the whole stroke to 1.4px makes straight and curved segments read as uniform weight.
- **Card corner radius is 15px** (not 20px, not 4px) — confirmed straight from Figma's Appearance
  panel on a real card, not eyeballed.
- **Card height is fixed** (`min-height: 656px`), not content-hugging — Figma's cards are a fixed
  656px regardless of how many bullet items a given card has. If you trim list items from a card,
  the card must NOT shrink; the price block should just sit lower with the same overall card height.
- **The site's self-hosted Inter webfont subset was originally broken site-wide** (not just on these
  pages): the 4 `inter-{300,400,500,600}.woff2` files only had ~157 glyphs, missing basic Cyrillic
  (А-Я/а-я), digits, and ₽ — so every Cyrillic character and digit on the ENTIRE site was silently
  falling back to the OS system font via the `font-family:'Inter',-apple-system,sans-serif` CSS
  chain, not true Inter. This was fixed by rebuilding the 4 woff2 files (subsetting
  `~/Library/Fonts/Inter_18pt-{Light,Regular,Medium,SemiBold}.ttf` down to
  `U+0000-00FF,U+0400-052F,U+2010-2027,U+2116,U+20B4,U+20BD` via `python3 -m fontTools.subset`).
  If glyphs still look wrong after a font-file fix, it's very likely a browser cache issue — hard
  refresh before debugging further. Original broken subsets backed up at
  `midnight-collective/fonts/.bak-original/`.
- **Content is 1:1 from Figma, EXCEPT deliberate manual trims the user asks for** (e.g. removing
  specific bullet items from specific cards by hand, after the page was already built and confirmed).
  Don't "correct" those trims back to match Figma later — they were an intentional edit, not a
  transcription gap.

## Future scope (not built yet, just context)

User wants to eventually select a subset of built cards across themes and generate a PDF
commercial proposal from them (a "compose KP" workflow). Out of scope until more themes exist.
