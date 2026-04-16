# Shopify (Liquid) Stack Rules

## Explore Agents

Launch up to 3 Explore agents in parallel:

### Agent 1: Templates, Sections & Blocks

- Based on the ticket description, find the templates and sections that need to be modified or created
- Check `templates/` for page, product, collection, and custom templates (`.json` template files)
- Review `sections/` for existing section files and their schema definitions
- Identify `blocks/` within sections that relate to the ticket
- Check `layout/` files (`theme.liquid`, custom layouts) for global changes

### Agent 2: Snippets, Assets & Settings

- Search `snippets/` for reusable Liquid partials that can be leveraged
- Look for existing patterns in similar sections/snippets to follow
- Check `assets/` for JavaScript and CSS files related to the ticket
- Review `config/settings_schema.json` for existing theme settings
- Note any existing `locales/` strings that need updating or new translations needed

### Agent 3: Config, Metafields & Supporting Code

- Check `templates/*.json` to understand how sections are assigned to pages
- Review `config/settings_data.json` for current theme configuration
- Identify if metafield definitions are needed (product, collection, page, etc.)
- Check for existing JavaScript modules and how they initialize (DOM-based, custom elements, etc.)
- Review any existing Liquid filters, tags, or objects used in related templates

**Important**: If the ticket involves new sections, verify the section schema structure follows existing patterns. Always check `settings_schema.json` before adding new theme-level settings to avoid conflicts.

## Stack-Specific Plan Sections

Include these sections in the plan between "Reusable Code" and "Implementation Steps":

### Section Schema Changes

| Section / Block         | Action | Description                        |
| ----------------------- | ------ | ---------------------------------- |
| `sections/hero.liquid`  | Modify | Add new block type for CTA         |
| `sections/faq.liquid`   | Create | New FAQ section with accordion     |

> If no section changes are needed, write "No section changes required."

### Theme Settings

<If applicable: new settings to add to `settings_schema.json` with type, id, label, and default.>

> If no theme settings changes are needed, write "No theme settings changes required."

### Metafields

<If applicable: metafield namespace, key, type, and which resource it belongs to.>

> If no metafields are needed, write "No metafields required."

### Assets

| File                    | Action | Description                    |
| ----------------------- | ------ | ------------------------------ |
| `assets/section-faq.js` | Create | Accordion toggle logic         |
| `assets/section-faq.css`| Create | FAQ section styles             |

> If no asset changes are needed, write "No asset changes required."

## Testing Sections

### Manual Testing

- Verify in the Theme Customizer that new sections/blocks appear correctly
- Test with different content lengths (empty, short, long) in section settings
- Verify the section renders correctly on product, collection, page, and other relevant templates
- Test add/remove/reorder of blocks within the section

### Browser Testing

- Responsive checks: mobile (375px), tablet (768px), desktop (1280px+)
- Cross-browser: Chrome, Firefox, Safari
- Check that lazy-loaded images and deferred scripts work correctly

## Quality Notes

- **Output escaping**: Liquid auto-escapes by default, but avoid `| raw` unless absolutely necessary
- **Performance**: Use `loading="lazy"` for images below the fold, defer non-critical JS
- **Section rendering**: Use `{% schema %}` correctly — validate JSON before saving
- **Accessibility**: Semantic HTML, ARIA labels on interactive elements, focus states on buttons/links
- **Translation**: Use `{{ 'key' | t }}` for all user-facing strings, update `locales/en.default.json`
- **Image handling**: Use `image_url` filter with size parameters, provide `srcset` for responsive images

## Verification Commands

```
- Run `shopify theme check` — no errors or warnings
- Preview with `shopify theme dev` — visual verification
- Test in Theme Customizer — all settings and blocks function correctly
- Validate Liquid syntax — no render errors in browser console
```
