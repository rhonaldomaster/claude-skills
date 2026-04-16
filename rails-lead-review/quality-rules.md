# Rails Code Quality Rules

Follow these rules strictly when writing or reviewing Ruby on Rails code.

---

## BACKEND RULES

### Rule 1: Avoid N+1 Queries

Always eager load associations when iterating over a collection.

```ruby
# Bad
posts = Post.all
posts.each { |post| puts post.author.name }

# Good
posts = Post.includes(:author).all
posts.each { |post| puts post.author.name }
```

Use `.pluck` or `.select` when you only need specific columns:

```ruby
# Bad (loads full objects)
User.all.map(&:email)

# Good
User.pluck(:email)
```

### Rule 2: Never Interpolate User Input in SQL

Always use parameterized queries or ActiveRecord methods.

```ruby
# Bad — SQL injection risk
User.where("email = '#{params[:email]}'")
Post.where("title LIKE '%#{params[:q]}%'")

# Good
User.where(email: params[:email])
Post.where("title LIKE ?", "%#{params[:q]}%")
```

### Rule 3: Always Whitelist with Strong Parameters

Never permit all parameters. Whitelist only what the action needs.

```ruby
# Bad
params.permit!
User.create(params)

# Good
def user_params
  params.require(:user).permit(:name, :email)
end
User.create(user_params)
```

Never whitelist sensitive attributes like `role`, `admin`, `deleted_at`.

### Rule 4: Database Constraints Mirror Model Validations

If the model validates presence, the column should also be `null: false` in the DB.

```ruby
# Model
validates :email, presence: true, uniqueness: true

# Migration — must match
add_column :users, :email, :string, null: false
add_index :users, :email, unique: true
```

Validations can be bypassed (`update_column`, bulk inserts). The DB constraint is the last line of defense.

### Rule 5: No Side Effects in Callbacks

Callbacks should only handle simple attribute assignments. Move anything else to a service object.

```ruby
# Bad
after_create :send_welcome_email

def send_welcome_email
  UserMailer.welcome(self).deliver_later  # side effect in callback
end

# Good — explicit in the controller or service
def create
  @user = User.new(user_params)
  if @user.save
    UserMailer.welcome(@user).deliver_later
    redirect_to @user
  end
end
```

### Rule 6: Use `deliver_later` for Mailers

Never block the request thread with synchronous email delivery.

```ruby
# Bad
UserMailer.welcome(user).deliver_now

# Good
UserMailer.welcome(user).deliver_later
```

### Rule 7: Pass IDs to Background Jobs, Not Objects

ActiveRecord objects can become stale between enqueue and perform time.

```ruby
# Bad
MyJob.perform_later(user)

# Good
MyJob.perform_later(user.id)

# In the job:
def perform(user_id)
  user = User.find(user_id)
  # ...
end
```

### Rule 8: Keep Controllers Thin

Controllers should only: authenticate, authorize, find the record, call one model/service method, redirect or render. Any business logic belongs in the model or a service object.

```ruby
# Bad — controller doing too much
def create
  @order = Order.new(order_params)
  @order.total = @order.items.sum(&:price)
  @order.tax = @order.total * 0.1
  @order.discount = current_user.member? ? 0.05 : 0
  @order.save
  OrderMailer.confirmation(@order).deliver_later
  InventoryService.decrement(@order.items)
end

# Good — delegate to service
def create
  result = OrderCreationService.call(order_params, current_user)
  result.success? ? redirect_to(result.order) : render(:new)
end
```

### Rule 9: Specify `dependent:` on Associations

Always decide what happens to child records when the parent is deleted.

```ruby
# Bad — orphaned records
has_many :posts

# Good
has_many :posts, dependent: :destroy
has_many :comments, dependent: :nullify
```

### Rule 10: Use Scopes for Reusable Queries

Named scopes are more expressive and composable than inline `where` chains.

```ruby
# Bad
Post.where(published: true).where("created_at > ?", 1.week.ago)

# Good
scope :published, -> { where(published: true) }
scope :recent, -> { where("created_at > ?", 1.week.ago) }

Post.published.recent
```

### Rule 11: No Magic Numbers — Use Enums or Constants

```ruby
# Bad
if user.status == 1
  # ...
end

# Good
enum status: { active: 0, suspended: 1, deleted: 2 }

if user.active?
  # ...
end
```

### Rule 12: Handle Exceptions Specifically

Never rescue the base `Exception` class. Always rescue specific exceptions and log context.

```ruby
# Bad
rescue Exception => e
  puts e.message

# Bad — swallows silently
rescue StandardError

# Good
rescue ActiveRecord::RecordNotFound => e
  Rails.logger.error("Record not found: #{e.message}")
  render :not_found
```

---

## VIEW / ERB RULES

### Rule 13: No Queries in Views

Views should only display data. Never call ActiveRecord queries from `.html.erb`.

```erb
<%# Bad %>
<% User.all.each do |user| %>
  <p><%= user.name %></p>
<% end %>

<%# Good — query in controller, display in view %>
<% @users.each do |user| %>
  <p><%= user.name %></p>
<% end %>
```

### Rule 14: No Complex Logic in ERB Templates

Move conditionals, transformations, and calculations to helpers or decorators.

```erb
<%# Bad %>
<% if user.created_at < 1.year.ago && user.orders.count > 10 %>
  <span>Loyal customer</span>
<% end %>

<%# Good — helper method %>
<% if loyal_customer?(user) %>
  <span>Loyal customer</span>
<% end %>
```

### Rule 15: Pass Locals to Partials

Partials should not depend on controller instance variables. Pass locals explicitly.

```erb
<%# Bad — partial reads @user directly %>
<%= render 'user_card' %>

<%# Good %>
<%= render partial: 'user_card', locals: { user: @user } %>
```

### Rule 16: Use `link_to` for Internal Navigation

Use Rails helpers for internal links. Reserve `<a href>` for external URLs.

```erb
<%# Bad %>
<a href="/users/<%= @user.id %>">Profile</a>

<%# Good %>
<%= link_to "Profile", user_path(@user) %>
```

Never use a `button` or `div` with `onclick` to navigate internally — use `link_to`.

### Rule 17: Eliminate Unnecessary Wrapper Elements

Remove elements that only wrap a single child without semantic or styling purpose. Move classes to the child.

```erb
<%# Bad %>
<div>
  <div class="text-lg font-bold"><%= @user.name %></div>
</div>

<%# Good %>
<div class="text-lg font-bold"><%= @user.name %></div>
```

### Rule 18: No Blank Lines Between ERB Siblings

Keep related elements together.

```erb
<%# Bad %>
<p>Line 1</p>

<p>Line 2</p>

<%# Good %>
<p>Line 1</p>
<p>Line 2</p>
```

### Rule 19: Extract Repetitive Markup to Partials

When the same structure repeats 3+ times, extract to a partial with a collection.

```erb
<%# Bad %>
<div class="card"><%= @user1.name %></div>
<div class="card"><%= @user2.name %></div>
<div class="card"><%= @user3.name %></div>

<%# Good %>
<%= render partial: 'user_card', collection: @users, as: :user %>
```

### Rule 20: Use Semantic HTML Elements

Prefer semantic tags over generic `<div>` and `<span>`.

```erb
<%# Bad %>
<div class="nav">...</div>
<div class="header">...</div>
<div class="article-body">...</div>

<%# Good %>
<nav>...</nav>
<header>...</header>
<article>...</article>
```

---

## TESTING RULES

### Rule 21: Test One Behavior Per Example

Each `it` block should have a single, focused expectation.

```ruby
# Bad
it "creates a user and sends email" do
  expect { post :create, params: {...} }.to change(User, :count).by(1)
  expect(ActionMailer::Base.deliveries.count).to eq(1)
end

# Good — two separate examples
it "creates a user" do
  expect { post :create, params: {...} }.to change(User, :count).by(1)
end

it "sends a welcome email" do
  post :create, params: {...}
  expect(ActionMailer::Base.deliveries.count).to eq(1)
end
```

### Rule 22: Use Factories, Not Fixtures

Prefer FactoryBot for test data creation. Use traits for variations.

```ruby
# Bad — large factory with all fields
FactoryBot.define do
  factory :user do
    name { "Test" }
    email { "test@test.com" }
    role { "admin" }
    confirmed { true }
    # 20 more attributes...
  end
end

# Good — minimal factory with traits
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }

    trait :admin do
      role { "admin" }
    end

    trait :confirmed do
      confirmed_at { Time.current }
    end
  end
end
```

---

## Quick Reference Checklist

When writing or reviewing Rails code, check:

**Backend**
- [ ] No N+1 queries — `.includes` used before iteration
- [ ] No SQL injection — parameterized queries used
- [ ] Strong params whitelisted properly
- [ ] DB constraints match model validations (`null: false`, unique indexes)
- [ ] No side effects in callbacks
- [ ] Mailers use `deliver_later`
- [ ] Background jobs receive IDs, not AR objects
- [ ] Controllers are thin — business logic in models/services
- [ ] `dependent:` specified on all `has_many` / `has_one`
- [ ] No `binding.pry` / `byebug` / `puts` left in code
- [ ] Enums or constants instead of magic numbers
- [ ] Exceptions rescued specifically

**Views / ERB**
- [ ] No DB queries in ERB files
- [ ] No complex logic in templates
- [ ] Partials receive locals, not instance variables
- [ ] `link_to` used for internal navigation
- [ ] No unnecessary wrapper elements
- [ ] No blank lines between ERB siblings
- [ ] Repeated markup extracted to partials
- [ ] Semantic HTML used where appropriate

**Testing**
- [ ] One expectation per example
- [ ] FactoryBot used (not fixtures)
- [ ] New public methods have specs
