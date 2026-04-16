# Rails Stack Rules

## Explore Agents

Launch up to 3 Explore agents in parallel:

### Agent 1: Routes, Controllers & Models

- Based on the ticket description, find the controllers, models, and routes that need to be modified or created
- Check `config/routes.rb` for existing API endpoints
- Review relevant controllers and their inheritance chain
- Identify affected models and their associations
- Check for existing database migrations related to the affected models

### Agent 2: Services, Concerns & Reusable Patterns

- Search `app/services/` for existing service objects that can be reused or extended
- Look for similar implementations in the codebase to follow as patterns
- Check `app/controllers/concerns/` and `app/models/concerns/` for shared behavior
- Review `app/blueprints/` or `app/serializers/` for existing serialization patterns
- Note any existing validations, scopes, or callbacks on related models

### Agent 3: Jobs, Specs & Supporting Code

- Search `app/jobs/` for related background jobs
- Check `spec/requests/` and `spec/models/` for existing test patterns on related resources
- Review `spec/factories/` for existing factories and traits that can be reused
- Check `app/mailers/` if the ticket involves notifications or emails
- Identify if new Sidekiq jobs or cron entries (`config/schedule.yml`) are needed

**Important**: If the ticket requires new database columns or tables, verify the current schema in `db/schema.rb` before proposing migrations.

## Stack-Specific Plan Sections

Include these sections in the plan between "Reusable Code" and "Implementation Steps":

### Database Changes

| Migration          | Description                              |
| ------------------ | ---------------------------------------- |
| `AddColumnToTable` | Add `column_name` (type) to `table_name` |
| `CreateTableName`  | New table with columns: ...              |

> If no database changes are needed, write "No database changes required."

### Background Jobs

<If applicable: job class, queue, schedule, and what it does.>
<If new cron entries are needed, specify the schedule.yml addition.>

> If no background jobs are needed, write "No background jobs required."

## Testing Sections

### Request Specs

- `spec/requests/<resource>_spec.rb` — what scenarios to cover (happy path, error cases, authorization)

### Model Specs

- `spec/models/<model>_spec.rb` — validations, associations, scopes, custom methods

### Service Specs

- `spec/services/<service>_spec.rb` — input/output, edge cases, error handling

> Include factories/traits that need to be created or updated in `spec/factories/`.

## Quality Notes

- **Consider N+1 queries**: When adding associations or new queries, specify `includes`/`eager_load` where needed
- **Ransack allowlists**: If adding filterable attributes, update `ransackable_attributes` and `ransackable_associations`
- **Strong parameters**: Required on all write endpoints

## Verification Commands

```
- Run `bundle exec rspec` — all tests pass
- Run `bundle exec rubocop` — no new offenses
- Run `bundle exec brakeman` — no new warnings
```
