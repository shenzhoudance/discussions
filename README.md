# Let's Build: With Ruby on Rails - Forum

# forum(discussions)

## Forum posts have
- a channel support
- markdown support
- date published
- code formatting
- comment count
- comments
    - comment author
    - comment voting
    - markdown support

## Forum Has
- filters(nice to have)
    - all
    - popular this week
    - popular all time
    - no replies yet
    - channels

## Guest users can
- read forum posts

## Admin users can
- create channels
- delete forum discussions

## Logged in user can
- have a profile
- search the forum
- comment/contribute to forum discussions
   - edit/delete their comments and discussions


## Possible Ways to extend
- forum ratings
discussion ratings（thumbs up or dowm）
reply ratings（thumbs up or dowm）
- Filter discussions

# Helpers
```
discussions_helper.rb
---
module DiscussionsHelper

  def discussion_author(discussion)
    user_signed_in? && current_user.id == discussion.user_id
  end

  def reply_author(reply)
    user_signed_in? && current_user.id == reply.user_id
  end
---

application_helper.rb
---
odule ApplicationHelper
  require 'redcarpet/render_strip'

  def has_role?(role)
    current_user && current_user.has_role?(role)
  end

  class CodeRayify < Redcarpet::Render::HTML
    def block_code(code, language)
      CodeRay.scan(code,language).div
    end
  end

  def markdown(text)
    coderayified = CodeRayify.new(:filter_html => true, :hard_wrap => true)
    options = {
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      autolink: true,
      lax_html_blocks: true
    }
    markdown_to_html = Redcarpet::Markdown.new(coderayified, options)
    markdown_to_html.render(text).html_safe
  end

  def strip_markdown(text)
    markdown_to_plain_text = Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
    markdown_to_plain_text.render(text).html_safe
  end

end
---
```
# GitList
```
gem 'bulma-rails', '~> 0.6.2'
gem 'simple_form', '~> 3.5'
gem 'devise', '~> 4.4', '>= 4.4.1'
gem 'gravatar_image_tag', '~> 1.2'
gem 'jquery-rails', '~> 4.3', '>= 4.3.1'
gem 'rolify', '~> 5.2'
gem 'cancancan', '~> 2.1', '>= 2.1.3'
gem 'friendly_id', '~> 5.2', '>= 5.2.3'
gem 'redcarpet', '~> 3.4'
gem 'coderay', '~> 1.1', '>= 1.1.2'
```

Adding an admin type of role with devise cancancan and rolify。
https://github.com/RolifyCommunity/rolify/wiki/Devise---CanCanCan---rolify-Tutorial

1、rails generate CanCan:ability
2、rails generate rolify Role User
```
discussions/app/models/ability.rb
---
class Ability
  include CanCan::Ability

  def initialize(user)
      user ||= User.new # guest user (not logged in)
      if user.has_role? :admin
        can :manage, :all
      else
        can :read, :all
      end

  end
end
```

3、use the resourcify method all models you want to put a role on.
for example,if we have the discussion model:

```
class discussion < ActiveRecord:Base
   resourcify
end
```

4、$ rake db:migrate

5、对应关系
```
$ rails c
$ @user = User.find("USER ID OF ANMIN USER")
$ @user = add_role "admin"
$ @user.roles #shoule output association of role id 1 of name "admin"
$ exit
```

# firendly ID - Prettier URLS
https://github.com/norman/friendly_id
```
$ rails g firendly_id
$ rake db:migrate
```

# Be sure to speclfy rails version before migration
```
create_friendly_id_slugs.rb
---
class CreateFriendlyIdSlugs < ActiveRecord::Migration[5.1]
  def change
    create_table :friendly_id_slugs do |t|
      t.string   :slug,           :null => false
      t.integer  :sluggable_id,   :null => false
      t.string   :sluggable_type, :limit => 50
      t.string   :scope
      t.datetime :created_at
    end
    add_index :friendly_id_slugs, :sluggable_id
    add_index :friendly_id_slugs, [:slug, :sluggable_type], length: { slug: 140, sluggable_type: 50 }
    add_index :friendly_id_slugs, [:slug, :sluggable_type, :scope], length: { slug: 70, sluggable_type: 50, scope: 70 }, unique: true
    add_index :friendly_id_slugs, :sluggable_type
  end
end
---
```
```
app/models/discussion.rb
---
extend FriendlyId
friendly_id :title, use: [:slugged, :finders]

def should_generate_new_friendly_id?
  title_changed?
end
---
```
```
app/models/channel.rb
---
extend FriendlyId
friendly_id :channel, use: [:slugged, :finders]

def should_generate_new_friendly_id?
  channel_changed?
end
---
```
```
app/models/reply.rb
---

  extend FriendlyId
  friendly_id :reply, use: [:slugged, :finders]

  def should_generate_new_friendly_id?
    reply_changed?
end
---
```
```
rails g migration AddSIugToDiscusstions slug:string
rails g migration AddSIugToChannels slug:string
rails g migration AddSIugToReplies slug:string
rake db:migrate
```

```
app/controllers/discussions_controller.rb
---
private
  # Use callbacks to share common setup or constraints between actions.
  def set_discussion
    @discussion = Discussion.find(params[:id])
end
```

```
app/controllers/replies_controller.rb
---

class RepliesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reply, only: [:edit, :update, :show, :destroy]
  before_action :set_discussion, only: [:create, :edit, :show, :update, :destroy]

  def create
    @reply = @discussion.replies.create(params[:reply].permit(:reply, :discussion_id))
    @reply.user_id = current_user.id

    respond_to do |format|
      if @reply.save
        format.html { redirect_to discussion_path(@discussion) }
        format.js # renders create.js.erb
      else
        format.html { redirect_to discussion_path(@discussion), notice: "Reply did not save. Please try again."}
        format.js
      end
    end
  end

  def new
  end


  def destroy
    @reply = @discussion.replies.find(params[:id])
    @reply.destroy
    redirect_to discussion_path(@discussion)
  end

  def edit
    @discussion = Discussion.find(params[:discussion_id])
    @reply = @discussion.replies.find(params[:id])
  end

  def update
    @reply = @discussion.replies.find(params[:id])
     respond_to do |format|
      if @reply.update(reply_params)
        format.html { redirect_to discussion_path(@discussion), notice: 'Reply was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @reply.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end

  private

  def set_discussion
    @discussion = Discussion.find(params[:discussion_id])
  end

  def set_reply
    @reply = Reply.find(params[:id])
  end

  def reply_params
    params.require(:reply).permit(:reply)
  end
end
```

# Optional：update existing records to new slugs
```
$ rails c
$ Discussion.find_each(&:save)
$ reload!
$ channel.find_each(&:save)
$ reply.find_each(&:save)
```

# Let's Build: With Ruby on Rails - Forum

```
cd workspace
cd discussions
git init
git add .
git commit -m "initial commit"
git remote add origin https://github.com/shenzhoudance/discussions.git
git push -u origin master
rails s
http://localhost:3000/
```
![image](https://i.loli.net/2018/04/02/5ac1969a5cbdd.png)
