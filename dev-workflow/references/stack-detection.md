# Stack Detection

Shared by `plan-ticket`, `workflow`, `pr-cycle`, and `generate-agent-rules`. Detect the project
stack by checking files in the current working directory:

| Check (in priority order)                                                            | Stack     |
| -------------------------------------------------------------------------------------| --------- |
| `Gemfile` exists AND contains `rails`                                                | Rails     |
| `package.json` exists AND contains `next`                                           | Next.js   |
| `composer.json` exists AND contains `yiisoft/yii2`                                  | PHP Yii2  |
| `style.css` with `Theme Name:` header OR `functions.php` with WordPress hooks       | WordPress |
| `config/settings_schema.json` OR `templates/*.json` + `sections/*.liquid`           | Shopify   |

If the stack cannot be detected, or more than one stack is present, ask the user which stack
applies before proceeding.
