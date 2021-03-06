require 'popit_watir_test_case'
require 'pry'
require 'net/http'
require 'uri'


class HostingTests < PopItWatirTestCase

  def test_site_can_be_deleted_and_fixture_loaded
    goto_hosting_site
    assert_match( /Welcome to PopIt/, @b.text )
  end

  def test_404_page
    goto_hosting_site
    goto '/instance/not_found'
    assert_equal 'Page not found', @b.title
    
    # Watir won't let us check that we got a 404 code
    u = URI.parse @b.url
    status_code = Net::HTTP.start(u.host,u.port){|http| http.head(u.request_uri).code }
    assert_equal '404', status_code
  end

  def test_create_instance
    goto_hosting_site
    delete_instance 'test'

    # check that the instance does not exist
    goto "/instance/test"
    assert_equal "Page not found", @b.title    

    # go to the create new site page
    goto_home_page
    @b.link(:text, 'Create your PopIt site').click

    # submit the form with no values, check for error
    @b.input(:value, 'Create your own PopIt').click
    assert_match "Error is 'regexp'", @b.text
    assert_match "Error is 'required'", @b.text    
    
    # check a slug that is too short
    @b.text_field(:name, 'slug').set("foo")
    @b.input(:value, 'Create your own PopIt').click
    assert_match "Error is 'regexp'", @b.text
    assert_match "Error is 'required'", @b.text    

    # check that a good slug does not error
    @b.text_field(:name, 'slug').set("test")
    @b.input(:value, 'Create your own PopIt').click
    assert_not_match "Error is 'regexp'", @b.text
    assert_match "Error is 'required'", @b.text    

    # check that a bad email is rejected
    #   NOTE - these tests are commented out as recent browsers catch the bad
    #   email address and show their own little warning. I can't seem to see how
    #   to test for that warning - it does not appear in the DOM.
    # @b.text_field(:name, 'email').set("bob")
    # @b.input(:value, 'Create your own PopIt').click
    # assert_match "Error is 'not_an_email'", @b.text    

    # submit good details
    @b.text_field(:name, 'email').set("bob@example.com")
    @b.input(:value, 'Create your own PopIt').click
    assert_match "Nearly Done! Now check your email...", @b.text    

    # check that the site is now reserved
    goto '/'
    @b.link(:text, "Create your PopIt site").click
    @b.text_field(:id, 'slug').set("test")
    @b.input(:value, 'Create your own PopIt').click
    assert_match "Error is 'slug_not_unique'", @b.text    

    # check that the instance page works
    goto "/instance/test"
    assert_equal "Pending: test", @b.title
            
    # go to the last email page
    goto "/_testing/last_email"
    @b.link.click

    # on the confirmr app page
    assert_match 'choose the type of the first politician to add to the site', @b.text
    @b.form.submit

    # check that we are on the instance url now
    assert_match /^http:\/\/test\./, @b.url
    assert_match 'PopIt : test', @b.text
    assert_equal 'People', @b.div(:id, 'content').h1.text
    assert_equal 'People', @b.title

    # check that we are logged in
    assert_match 'Hello bob@example.com', @b.div(:id, 'signed_in').text
            
  end

end
