require 'byebug'
require_relative "acceptance_helper"
require_relative "../../DbHandler.rb"

class LoginLogoutSpec < Minitest::Spec 
  include ::Capybara::DSL
  include ::Capybara::Minitest::Assertions

  def self.test_order
    :alpha #run the tests in this file in order
  end

  before do
  end
  
  after do 
    Capybara.reset_sessions!
  end

  def login
    visit '/user/login'
    within("#login-form") do
      fill_in('username', with: "apple@frukt.se")
      fill_in('password', with: "123")
      click_button 'Log in'
    end
  end
  
  it 'user new and log out' do
    visit '/user/new'
    within("#login-form") do
      fill_in('username', with: "apple@frukt.se")
      fill_in('password', with: "123")
      click_button 'Create account'
    end
  
    find('a', text: 'logout').click
  end

  it 'log in create post' do
    login
    visit '/post/new'
    within("#post-form") do
      fill_in('Title', with: "test-title")
      fill_in('content', with: "test-content")
      click_button 'create'
    end
    
  end
  
  it 'comment on post' do
    login
    id = Post.get_last_id()
    visit "/post/show/#{id}"
    find('a', id: 'new-comment').click

    within("#comment-form") do
      fill_in('content', with: "test-comment")
      click_button 'create'
    end
    
  end
  
  it 'comment on comment' do 
    login
    id = Post.get_last_id()
    comment_id = Comment.get_last_id()
    visit "/post/show/#{id}"
    find('a', class: "new-comment/#{id}/#{comment_id}").click
  
    within("#comment-form") do
      fill_in('content', with: "test-comment")
      click_button 'create'
    end


  end
  
  it 'log in and delete' do 
    login
    within('#delete') do
      click_button 'Delete'
    end

  end


end