# PHP (Yii2) Stack Rules

## Explore Agents

Launch up to 3 Explore agents in parallel:

### Agent 1: Controllers, Models & Routes

- Based on the ticket description, find the controllers and models that need to be modified or created
- Check URL rules in `config/web.php` or `config/urlManager.php` for existing routes
- Review relevant controllers in `controllers/` and their action methods
- Identify affected models in `models/` — ActiveRecord classes, their `rules()`, `attributeLabels()`, and relations
- Check for existing database migrations in `migrations/` related to the affected models

### Agent 2: Views, Widgets & Reusable Components

- Search `views/` for existing view files and layouts related to the ticket
- Look for reusable widgets in `widgets/` or `components/`
- Check for existing form models in `models/` (non-ActiveRecord classes used for forms/search)
- Review `assets/` for AssetBundle classes and their registered CSS/JS
- Note any existing behaviors, validators, or base classes that can be extended

### Agent 3: Commands, Tests & Supporting Code

- Search `commands/` for existing console commands
- Check `tests/` for existing test patterns (unit, functional, acceptance)
- Review `tests/fixtures/` for existing test fixtures
- Check `mail/` for email templates if the ticket involves notifications
- Identify if queue jobs (`yii\queue\`) are needed and check existing job classes

**Important**: If the ticket requires new database columns or tables, verify the current schema by checking the latest migrations and the database. Always generate migrations using `yii migrate/create`.

## Stack-Specific Plan Sections

Include these sections in the plan between "Reusable Code" and "Implementation Steps":

### Database Changes

| Migration                      | Description                              |
| ------------------------------ | ---------------------------------------- |
| `m_XXXXXX_XXXXXX_add_column`   | Add `column_name` (type) to `table_name` |
| `m_XXXXXX_XXXXXX_create_table` | New table with columns: ...              |

> If no database changes are needed, write "No database changes required."

### Views & Layouts

| View File                    | Action | Description               |
| ---------------------------- | ------ | ------------------------- |
| `views/controller/action.php`| Modify | Add new form field        |
| `views/controller/index.php` | Create | New listing page          |

> If no view changes are needed, write "No view changes required."

### Queue Jobs

<If applicable: job class, queue channel, and what it does.>

> If no queue jobs are needed, write "No queue jobs required."

## Testing Sections

### Unit Tests

- `tests/unit/<Model>Test.php` — validation rules, business logic, relations

### Functional Tests

- `tests/functional/<Controller>Test.php` — action responses, redirects, access control

### Fixtures

- List fixtures that need to be created or updated in `tests/fixtures/`

## Quality Notes

- **SQL injection**: Always use parameterized queries or ActiveRecord — never concatenate SQL
- **XSS prevention**: Use `Html::encode()` for output, `HtmlPurifier` for rich text
- **CSRF**: Ensure forms include CSRF tokens (enabled by default in Yii2)
- **Input validation**: Define `rules()` in models — never trust raw `$_POST`/`$_GET`
- **RBAC**: If the ticket involves permissions, check existing `authManager` rules before adding new ones

## Verification Commands

```
- Check PHP syntax: `find . -name "*.php" -exec php -l {} \;`
- Run migrations: `php yii migrate --interactive=0`
- Run tests: `php vendor/bin/codecept run` or `php vendor/bin/phpunit`
- Check code style: `php vendor/bin/phpcs --standard=PSR12 <file>` (if available)
```
