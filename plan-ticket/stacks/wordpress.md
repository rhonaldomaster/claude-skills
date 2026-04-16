# WordPress Stack Rules

## Explore Agents

Launch up to 3 Explore agents in parallel:

### Agent 1: Theme Structure & Templates

- Based on the ticket description, find the theme templates and template parts that need to be modified or created
- Check the active theme directory for `style.css`, `functions.php`, and template hierarchy
- Review `template-parts/` or `parts/` for reusable components
- Identify page templates, archive templates, and custom post type templates
- Check for `theme.json` or Customizer settings if the ticket involves styling or theme options

### Agent 2: Custom Post Types, Taxonomies & Hooks

- Search `functions.php` and `inc/` or `includes/` for custom post type and taxonomy registrations
- Look for existing action/filter hooks related to the ticket's functionality
- Check for existing shortcodes, widgets, or Gutenberg blocks
- Review ACF (Advanced Custom Fields) field groups if present (`acf-json/` or registered in PHP)
- Note any existing custom queries (`WP_Query`, `get_posts`) that relate to the ticket

### Agent 3: Assets, Plugins & Supporting Code

- Check how assets are enqueued (`wp_enqueue_style`, `wp_enqueue_script`) in `functions.php` or `inc/`
- Review existing JavaScript files and their dependencies
- Identify plugin dependencies — check which plugins are active and if any provide APIs used by the theme
- Check for AJAX handlers (`wp_ajax_`, `wp_ajax_nopriv_`) if the ticket involves async operations
- Review any REST API custom endpoints registered with `register_rest_route`

**Important**: If the ticket involves database queries, verify the table structure using `$wpdb` or check if custom tables exist. Always prefer WordPress APIs (`WP_Query`, `get_post_meta`, etc.) over direct SQL.

## Stack-Specific Plan Sections

Include these sections in the plan between "Reusable Code" and "Implementation Steps":

### Template Changes

| Template / Part          | Action | Description                    |
| ------------------------ | ------ | ------------------------------ |
| `template-parts/card.php`| Modify | Add new field output            |
| `single-event.php`       | Create | New single template for events  |

> If no template changes are needed, write "No template changes required."

### Custom Fields

<If applicable: ACF field group changes, custom meta boxes, or post meta additions.>
<Specify field names, types, and which post types they attach to.>

> If no custom field changes are needed, write "No custom field changes required."

### Hooks & Filters

<If applicable: list new or modified actions/filters with their callbacks and priority.>

> If no hook changes are needed, write "No hook changes required."

## Testing Sections

### Manual Testing

- List specific pages/post types to verify after changes
- Check different user roles if the feature involves permissions
- Test with and without relevant plugins active

### Browser Testing

- Responsive checks: mobile, tablet, desktop
- Cross-browser: Chrome, Firefox, Safari at minimum
- Accessibility: keyboard navigation, screen reader, color contrast

## Quality Notes

- **Escape output**: Always use `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses()` for output
- **Sanitize input**: Use `sanitize_text_field()`, `absint()`, etc. for all user input
- **Nonces**: Required on all form submissions and AJAX requests
- **Translation ready**: Use `__()`, `_e()`, `esc_html__()` for all user-facing strings
- **Enqueue properly**: Never hardcode `<script>` or `<link>` tags — use `wp_enqueue_*`

## Verification Commands

```
- Check PHP syntax: `find . -name "*.php" -exec php -l {} \;`
- Check WordPress coding standards: `phpcs --standard=WordPress <file>` (if available)
- Verify no PHP errors in `wp-content/debug.log` with `WP_DEBUG` enabled
- Test with default theme (Twenty Twenty-Four) to isolate theme-specific issues if debugging
```
