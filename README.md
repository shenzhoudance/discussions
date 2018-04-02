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

关于专案的增量开发的流程体系：

## 一、基本页面的开发
- gems 的安装
- welcome 页面的制作 + layouts 页面的制作
- devise 用户系统的制作

##  二、基本功能的开发
- discussions 技能功能的制作

##  三、核心功能的开发

##  四、页面设计的美化

##  五、专案开发的部署

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

## 一、基本页面的开发
- gems 的安装
- welcome 页面的制作 + layouts 页面的制作
- devise 用户系统的制作

```
git checkout -b gems
---
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
---
group :development, :test do
---
gem 'guard', '~> 2.14', '>= 2.14.2'
gem 'guard-livereload', '~> 2.5', require: false
---
bundle install
guard init livereload
bundle exec guard
exit
---
rails generate simple_form:install
rails generate devise:install
rails generate devise:User
rake db:migrate
rails g controller home index
```
```
---
app/views/layouts/application.html.erb
---
<!DOCTYPE html>
<html>
  <head>
    <title>Discussions</title>
    <%= csrf_meta_tags %>

    <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>
  </head>

  <body>
    <%= yield %>
  </body>
</html>
---
<!DOCTYPE html>
<html>
  <head>
    <title>Discussions</title>
    <%= csrf_meta_tags %>

    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%= stylesheet_link_tag "https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" %>
    <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>

  </head>

  <body>
    <% if flash[:notice] %>
      <div class="notification is-success global-notification">
        <p class="notice"><%= notice %></p>
      </div>
    <% end %>
    <% if flash[:alert] %>
    <div class="notification is-danger global-notification">
      <p class="alert"><%= alert %></p>
    </div>
    <% end %>
     <nav class="navbar is-light" role="navigation" aria-label="main navigation">
      <div class="navbar-brand">
        <%= link_to root_path, class:"navbar-item" do %>
          <h1 class="title is-5">Discussions</h1>
        <% end  %>
      <div class="navbar-burger burger" data-target="navbar">
        <span></span>
        <span></span>
        <span></span>
      </div>
    </div>

      <div id="navbar" class="navbar-menu">
        <div class="navbar-end">
          <% if user_signed_in? %>
          <div class="navbar-item">
            <div class="field is-grouped">
              <%= link_to 'New Discussion', new_discussion_path, class:"button is-info" %>
            </div>
          </div>
          <div class="navbar-item has-dropdown is-hoverable">
            <%= link_to 'Account', edit_user_registration_path, class: "navbar-link" %>
            <div class="navbar-dropdown is-right">
              <%= link_to current_user.username, edit_user_registration_path, class:"navbar-item" %>
              <%= link_to "Log Out", destroy_user_session_path, method: :delete, class:"navbar-item" %>
            </div>
          </div>
         <% else %>
         <div class="navbar-item">
          <div class="field is-grouped">

            <p class="control">
              <%= link_to 'New Discussion', new_discussion_path, class:"button is-info" %>
            </p>

            <p class="control">
              <%= link_to "Sign In", new_user_session_path, class: "button is-light"%>
            </p>

            <p class="control">
              <%= link_to "Sign up", new_user_registration_path, class: "button is-light" %>
            </p>
          </div>
          </div>
          <% end %>

        </div>
    </div>
  </nav>

<section class="section">
  <div class="container">
    <%= yield %>
  </div>
</section>

  </body>
</html>
```
```
app/assets/stylesheets/application.scss
---
@import "bulma";
```
![image](https://ws2.sinaimg.cn/large/006tKfTcgy1fpybue1hmhj31kw07q3zk.jpg)
![image](https://ws2.sinaimg.cn/large/006tKfTcgy1fpybvuje7uj31kw0fa764.jpg)
![image](https://ws2.sinaimg.cn/large/006tKfTcgy1fpybvzaublj31kw0fd40a.jpg)

```
app/controllers/registrations_controller.rb
---
class RegistrationsController < Devise::RegistrationsController

  private

  def sign_up_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :current_password)
  end

end
---
```
```
rails g migration addUsernameToUsers username:string
rake db:migrate
rails server
```
![image](https://ws2.sinaimg.cn/large/006tKfTcgy1fpyc6fp50cj31kw0ceq4n.jpg)

##  二、基本功能的开发
- discussions 技能功能的制作
```
git checkout -b scaffold-discussion
rails g scaffold Discussion title:string content:text
rake db:migrate
---
config/routes.rb
Rails.application.routes.draw do
  resources :discussions
  devise_for :users
  root 'discussions#index'
end
---
```
![image](https://ws2.sinaimg.cn/large/006tKfTcgy1fpycwfd0apj31kw0a6t9u.jpg)
```
app/assets/stylesheets/application.scss
---
@import "bulma";
@import "functions";

.image {
  border-radius: 50%;
  img {
    border-radius: 50%;
  }
}

.notification:not(:last-child) {
  margin-bottom: 0;
}

.textarea {
  height: 250px;
  font-family: Monaco, san-serif;
  font-size: .9rem;
  padding: 1rem;
}

.discussion-title {
  margin-bottom: 0;
}
---
app/assets/stylesheets/_functions.scss
---
// Border
// -----------------------------------
.border-light { border: 1px solid #ddd; }
.border-radius-2 { border-radius: 2px; }
.border-radius-4 { border-radius: 4px; }
.border-radius-6 { border-radius: 6px; }
.border-radius-50 { border-radius: 50%; }

.bb { border-bottom: 1px solid #ddd; }

.bb-not-last {
  border-bottom: 1px solid #ddd;
  &:last-of-type {
    border-bottom: 0;
  }
}


// Spacing
// Base:      p = padding; m = margin
// Modifiers: a = all; h = horizontal; v = vertical; t,r,b,l = top, etc.
// Factors:   10 through 100
// ===========================================================================

$spacing-10:  10px;
$spacing-20:  20px;
$spacing-30:  30px;
$spacing-40:  40px;
$spacing-50:  50px;
$spacing-60:  60px;
$spacing-70:  70px;
$spacing-80:  80px;
$spacing-90:  90px;
$spacing-100: 100px;

// Padding
// ------------------------------------

.pa0   { padding: 0; }
.pa10  { padding: $spacing-10; }
.pa20  { padding: $spacing-20; }
.pa30  { padding: $spacing-30; }
.pa40  { padding: $spacing-40; }
.pa50  { padding: $spacing-50; }
.pa60  { padding: $spacing-60; }
.pa70  { padding: $spacing-70; }
.pa80  { padding: $spacing-80; }
.pa90  { padding: $spacing-90; }
.pa100 { padding: $spacing-100; }

.pl0   { padding-left: 0; }
.pl10  { padding-left: $spacing-10; }
.pl20  { padding-left: $spacing-20; }
.pl30  { padding-left: $spacing-30; }
.pl40  { padding-left: $spacing-40; }
.pl50  { padding-left: $spacing-50; }
.pl60  { padding-left: $spacing-60; }
.pl70  { padding-left: $spacing-70; }
.pl80  { padding-left: $spacing-80; }
.pl90  { padding-left: $spacing-90; }
.pl100 { padding-left: $spacing-100; }

.pr0   { padding-right: 0; }
.pr10  { padding-right: $spacing-10; }
.pr20  { padding-right: $spacing-20; }
.pr30  { padding-right: $spacing-30; }
.pr40  { padding-right: $spacing-40; }
.pr50  { padding-right: $spacing-50; }
.pr60  { padding-right: $spacing-60; }
.pr70  { padding-right: $spacing-70; }
.pr80  { padding-right: $spacing-80; }
.pr90  { padding-right: $spacing-90; }
.pr100 { padding-right: $spacing-100; }

.pb0   { padding-bottom: 0; }
.pb10  { padding-bottom: $spacing-10; }
.pb20  { padding-bottom: $spacing-20; }
.pb30  { padding-bottom: $spacing-30; }
.pb40  { padding-bottom: $spacing-40; }
.pb50  { padding-bottom: $spacing-50; }
.pb60  { padding-bottom: $spacing-60; }
.pb70  { padding-bottom: $spacing-70; }
.pb80  { padding-bottom: $spacing-80; }
.pb90  { padding-bottom: $spacing-90; }
.pb100 { padding-bottom: $spacing-100; }

.pt0   { padding-top: 0; }
.pt10  { padding-top: $spacing-10; }
.pt20  { padding-top: $spacing-20; }
.pt30  { padding-top: $spacing-30; }
.pt40  { padding-top: $spacing-40; }
.pt50  { padding-top: $spacing-50; }
.pt60  { padding-top: $spacing-60; }
.pt70  { padding-top: $spacing-70; }
.pt80  { padding-top: $spacing-80; }
.pt90  { padding-top: $spacing-90; }
.pt100 { padding-top: $spacing-100; }

.pv0   { padding-top: 0; padding-bottom: 0; }
.pv10  { padding-top: $spacing-10; padding-bottom: $spacing-10; }
.pv20  { padding-top: $spacing-20; padding-bottom: $spacing-20; }
.pv30  { padding-top: $spacing-30; padding-bottom: $spacing-30; }
.pv40  { padding-top: $spacing-40; padding-bottom: $spacing-40; }
.pv50  { padding-top: $spacing-50; padding-bottom: $spacing-50; }
.pv60  { padding-top: $spacing-60; padding-bottom: $spacing-60; }
.pv70  { padding-top: $spacing-70; padding-bottom: $spacing-70; }
.pv80  { padding-top: $spacing-80; padding-bottom: $spacing-80; }
.pv90  { padding-top: $spacing-90; padding-bottom: $spacing-90; }
.pv100 { padding-top: $spacing-100;padding-bottom: $spacing-100;  }

.ph0   { padding-left: 0; padding-right: 0; }
.ph10  { padding-left: $spacing-10; padding-right: $spacing-10; }
.ph20  { padding-left: $spacing-20; padding-right: $spacing-20; }
.ph30  { padding-left: $spacing-30; padding-right: $spacing-30; }
.ph40  { padding-left: $spacing-40; padding-right: $spacing-40; }
.ph50  { padding-left: $spacing-50; padding-right: $spacing-50; }
.ph60  { padding-left: $spacing-60; padding-right: $spacing-60; }
.ph70  { padding-left: $spacing-70; padding-right: $spacing-70; }
.ph80  { padding-left: $spacing-80; padding-right: $spacing-80; }
.ph90  { padding-left: $spacing-90; padding-right: $spacing-90; }
.ph100 { padding-left: $spacing-100;padding-right: $spacing-100;  }

// Margins
// ------------------------------------

.m0auto { margin: 0 auto; }

.ma0   { margin: 0; }
.ma10  { margin: $spacing-10; }
.ma20  { margin: $spacing-20; }
.ma30  { margin: $spacing-30; }
.ma40  { margin: $spacing-40; }
.ma50  { margin: $spacing-50; }
.ma60  { margin: $spacing-60; }
.ma70  { margin: $spacing-70; }
.ma80  { margin: $spacing-80; }
.ma90  { margin: $spacing-90; }
.ma100 { margin: $spacing-100; }

.ml0   { margin-left: 0; }
.ml10  { margin-left: $spacing-10; }
.ml20  { margin-left: $spacing-20; }
.ml30  { margin-left: $spacing-30; }
.ml40  { margin-left: $spacing-40; }
.ml50  { margin-left: $spacing-50; }
.ml60  { margin-left: $spacing-60; }
.ml70  { margin-left: $spacing-70; }
.ml80  { margin-left: $spacing-80; }
.ml90  { margin-left: $spacing-90; }
.ml100 { margin-left: $spacing-100; }

.mr0   { margin-right: 0; }
.mr10  { margin-right: $spacing-10; }
.mr20  { margin-right: $spacing-20; }
.mr30  { margin-right: $spacing-30; }
.mr40  { margin-right: $spacing-40; }
.mr50  { margin-right: $spacing-50; }
.mr60  { margin-right: $spacing-60; }
.mr70  { margin-right: $spacing-70; }
.mr80  { margin-right: $spacing-80; }
.mr90  { margin-right: $spacing-90; }
.mr100 { margin-right: $spacing-100; }

.mb0   { margin-bottom: 0; }
.mb10  { margin-bottom: $spacing-10; }
.mb20  { margin-bottom: $spacing-20; }
.mb30  { margin-bottom: $spacing-30; }
.mb40  { margin-bottom: $spacing-40; }
.mb50  { margin-bottom: $spacing-50; }
.mb60  { margin-bottom: $spacing-60; }
.mb70  { margin-bottom: $spacing-70; }
.mb80  { margin-bottom: $spacing-80; }
.mb90  { margin-bottom: $spacing-90; }
.mb100 { margin-bottom: $spacing-100; }

.mt0   { margin-top: 0; }
.mt10  { margin-top: $spacing-10; }
.mt20  { margin-top: $spacing-20; }
.mt30  { margin-top: $spacing-30; }
.mt40  { margin-top: $spacing-40; }
.mt50  { margin-top: $spacing-50; }
.mt60  { margin-top: $spacing-60; }
.mt70  { margin-top: $spacing-70; }
.mt80  { margin-top: $spacing-80; }
.mt90  { margin-top: $spacing-90; }
.mt100 { margin-top: $spacing-100; }

.mv0   { margin-top: 0; margin-bottom: 0; }
.mv10  { margin-top: $spacing-10; margin-bottom: $spacing-10; }
.mv20  { margin-top: $spacing-20; margin-bottom: $spacing-20; }
.mv30  { margin-top: $spacing-30; margin-bottom: $spacing-30; }
.mv40  { margin-top: $spacing-40; margin-bottom: $spacing-40; }
.mv50  { margin-top: $spacing-50; margin-bottom: $spacing-50; }
.mv60  { margin-top: $spacing-60; margin-bottom: $spacing-60; }
.mv70  { margin-top: $spacing-70; margin-bottom: $spacing-70; }
.mv80  { margin-top: $spacing-80; margin-bottom: $spacing-80; }
.mv90  { margin-top: $spacing-90; margin-bottom: $spacing-90; }
.mv100 { margin-top: $spacing-100;margin-bottom: $spacing-100;  }

.mh0   { margin-left: 0; margin-right: 0; }
.mh10  { margin-left: $spacing-10; margin-right: $spacing-10; }
.mh20  { margin-left: $spacing-20; margin-right: $spacing-20; }
.mh30  { margin-left: $spacing-30; margin-right: $spacing-30; }
.mh40  { margin-left: $spacing-40; margin-right: $spacing-40; }
.mh50  { margin-left: $spacing-50; margin-right: $spacing-50; }
.mh60  { margin-left: $spacing-60; margin-right: $spacing-60; }
.mh70  { margin-left: $spacing-70; margin-right: $spacing-70; }
.mh80  { margin-left: $spacing-80; margin-right: $spacing-80; }
.mh90  { margin-left: $spacing-90; margin-right: $spacing-90; }
.mh100 { margin-left: $spacing-100;margin-right: $spacing-100; }
---
```
![image](https://ws3.sinaimg.cn/large/006tKfTcgy1fpyd0nc5cej31kw0aadh5.jpg)

```
rails g migration addUserIdToDiscussions user_id:integer
rake db:migrate
rails g model Reply reply:text
rake db:migrate
rails g scaffold Channel channel:string
rails g migration addDiscussionIdToReplies discussin_id:integer
rake db:migrate
rails g migration addUserIdToReplies user_id:integer
rake db:migrate
rails g migration addChannelIdToDiscussions channel_id:integer
rake db:migrate
rails g migration addDiscussionIdToChannels discussion_id:integer
```
![image](https://ws4.sinaimg.cn/large/006tKfTcgy1fpydkw12k3j31ji0jwdld.jpg)

```
config/routes.rb
---
Rails.application.routes.draw do
  resources :channels
  resources :discussions
  devise_for :users, controllers: { registrations: 'registrations' }
  root 'discussions#index'
end
---
Rails.application.routes.draw do
resources :channels
resources :discussions do
  resources :replies
end

devise_for :users, controllers: { registrations: 'registrations' }
root 'discussions#index'
end
```
# 对应关系的处理
```
app/models/discussion.rb
---
belongs_to :channel
belongs_to :user
has_many :replies, dependent: :destroy

validates :title, :content, presence: true
end
---
app/models/reply.rb
---
belongs_to :discussion
belongs_to :user
validates :reply, presence: true
end
----
app/models/channel.rb
---
has_many :discussions
has_many :users, through: :discussions
end
---
app/models/user.rb
---
devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :trackable, :validatable

 has_many :discussions, dependent: :destroy
 has_many :channels, through: :discussions
end
```
![image](https://ws3.sinaimg.cn/large/006tKfTcgy1fpyfe8a5fgj31kw0qyaio.jpg)

```
git checkout -b devise-controller
app/controllers/discussions_controller.rb
---
class DiscussionsController < ApplicationController
  before_action :set_discussion, only: [:show, :edit, :update, :destroy]

  # GET /discussions
  # GET /discussions.json
  def index
    @discussions = Discussion.all
  end

  # GET /discussions/1
  # GET /discussions/1.json
  def show
  end

  # GET /discussions/new
  def new
    @discussion = Discussion.new
  end

  # GET /discussions/1/edit
  def edit
  end

  # POST /discussions
  # POST /discussions.json
  def create
    @discussion = Discussion.new(discussion_params)

    respond_to do |format|
      if @discussion.save
        format.html { redirect_to @discussion, notice: 'Discussion was successfully created.' }
        format.json { render :show, status: :created, location: @discussion }
      else
        format.html { render :new }
        format.json { render json: @discussion.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /discussions/1
  # PATCH/PUT /discussions/1.json
  def update
    respond_to do |format|
      if @discussion.update(discussion_params)
        format.html { redirect_to @discussion, notice: 'Discussion was successfully updated.' }
        format.json { render :show, status: :ok, location: @discussion }
      else
        format.html { render :edit }
        format.json { render json: @discussion.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /discussions/1
  # DELETE /discussions/1.json
  def destroy
    @discussion.destroy
    respond_to do |format|
      format.html { redirect_to discussions_url, notice: 'Discussion was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_discussion
      @discussion = Discussion.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def discussion_params
      params.require(:discussion).permit(:title, :content)
    end
end
---
lass DiscussionsController < ApplicationController
  before_action :set_discussion, only: [:show, :edit, :update, :destroy]
  before_action :find_channels, only: [:index, :show, :new, :edit]
  before_action :authenticate_user!, except: [:index, :show]

  # GET /discussions
  # GET /discussions.json
  def index
    @discussions = Discussion.all.order('created_at desc')
  end

  # GET /discussions/1
  # GET /discussions/1.json
  def show
    @discussions = Discussion.all.order('created_at desc')
  end

  # GET /discussions/new
  def new
    @discussion = current_user.discussions.build
  end

  # GET /discussions/1/edit
  def edit
  end

  # POST /discussions
  # POST /discussions.json
  def create
    @discussion = current_user.discussions.build(discussion_params)

    respond_to do |format|
      if @discussion.save
        format.html { redirect_to @discussion, notice: 'Discussion was successfully created.' }
        format.json { render :show, status: :created, location: @discussion }
      else
        format.html { render :new }
        format.json { render json: @discussion.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /discussions/1
  # PATCH/PUT /discussions/1.json
  def update
    respond_to do |format|
      if @discussion.update(discussion_params)
        format.html { redirect_to @discussion, notice: 'Discussion was successfully updated.' }
        format.json { render :show, status: :ok, location: @discussion }
      else
        format.html { render :edit }
        format.json { render json: @discussion.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /discussions/1
  # DELETE /discussions/1.json
  def destroy
    @discussion.destroy
    respond_to do |format|
      format.html { redirect_to discussions_url, notice: 'Discussion was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_discussion
      @discussion = Discussion.find(params[:id])
    end

    def find_channels
      @channels = Channel.all.order('created_at desc')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def discussion_params
      params.require(:discussion).permit(:title, :content, :channel_id)
    end
end
---
app/controllers/channels_controller.rb
---
class ChannelsController < ApplicationController
  before_action :set_channel, only: [:show, :edit, :update, :destroy]

  # GET /channels
  # GET /channels.json
  def index
    @channels = Channel.all
  end

  # GET /channels/1
  # GET /channels/1.json
  def show
  end

  # GET /channels/new
  def new
    @channel = Channel.new
  end

  # GET /channels/1/edit
  def edit
  end

  # POST /channels
  # POST /channels.json
  def create
    @channel = Channel.new(channel_params)

    respond_to do |format|
      if @channel.save
        format.html { redirect_to @channel, notice: 'Channel was successfully created.' }
        format.json { render :show, status: :created, location: @channel }
      else
        format.html { render :new }
        format.json { render json: @channel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /channels/1
  # PATCH/PUT /channels/1.json
  def update
    respond_to do |format|
      if @channel.update(channel_params)
        format.html { redirect_to @channel, notice: 'Channel was successfully updated.' }
        format.json { render :show, status: :ok, location: @channel }
      else
        format.html { render :edit }
        format.json { render json: @channel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /channels/1
  # DELETE /channels/1.json
  def destroy
    @channel.destroy
    respond_to do |format|
      format.html { redirect_to channels_url, notice: 'Channel was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_channel
      @channel = Channel.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def channel_params
      params.require(:channel).permit(:channel)
    end
end
---
class ChannelsController < ApplicationController
  before_action :set_channel, only: [:show, :edit, :update, :destroy]

  # GET /channels
  # GET /channels.json
  def index
    @channels = Channel.all
    @discussions = Discussion.all.order('created_at desc')
  end

  # GET /channels/1
  # GET /channels/1.json
  def show
    @discussions = Discussion.where('channel_id = ?', @channel.id)
    @channels = Channel.all
  end

  # GET /channels/new
  def new
    @channel = Channel.new
  end

  # GET /channels/1/edit
  def edit
  end

  # POST /channels
  # POST /channels.json
   def create
    @channel = Channel.new(channel_params)

    respond_to do |format|
      if @channel.save
        format.html { redirect_to channels_path, notice: 'Channel was successfully created.' }
        format.json { render :show, status: :created, location: @channel }
      else
        format.html { render :new }
        format.json { render json: @channel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /channels/1
  # PATCH/PUT /channels/1.json
  def update
    respond_to do |format|
      if @channel.update(channel_params)
        format.html { redirect_to channels_path, notice: 'Channel was successfully updated.' }
        format.json { render :show, status: :ok, location: @channel }
      else
        format.html { render :edit }
        format.json { render json: @channel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /channels/1
  # DELETE /channels/1.json
  def destroy
    @channel.destroy
    respond_to do |format|
      format.html { redirect_to channels_url, notice: 'Channel was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_channel
      @channel = Channel.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def channel_params
      params.require(:channel).permit(:channel)
    end
end
---
