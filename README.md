# README

This repository contains the Harvard Digital Collections web application, a [Blacklight](http://projectblacklight.org/) instance that uses the Harvard LibraryCloud Item API as a backend in place of
the standard Solr backend. 

Live site: http://digitalcollections.library.harvard.edu/catalog/

# Deployment

## Heroku

* Create a new application on Heroku
* If not already installed, install the Heroku command-line tools as 
per https://devcenter.heroku.com/articles/heroku-command-line and login to your Heroku account
* On the "Deploy" tab for your application, select "Heroku Git" as the deployment method
* Clone this repository
* Add the Heroku repository as a remote

```
heroku git:remote -a [MY APPLICATION NAME]
```
* Push the code to Heroku

```
git push heroku master
```
* On the "Settings" tab add a new Config Variable named `LC_API_KEY` with the value of your 
LibraryCloud API key. (This is only required for the "Add to Collection" functionality)
   
## RHEL

* Install Postgres and the Postgres development libraries, if not already installed. Make sure the database is running

* Install Ruby following these instructions: https://gorails.com/setup/ubuntu/17.10#ruby-rbenv

```sh
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

rbenv install 2.5.0
rbenv global 2.5.0
ruby -v

gem install bundler
rbenv rehash
```

* Install Rails

```sh
gem install rails -v 5.1.4
rbenv rehash
```

* Install the Application

```sh
git clone https://github.com/harvard-library/STLee-blacklight.git
cd STLee-blacklight/
bundle install
```

* Configure the database connection

Edit `config/database.yml` with credentials that match the Postgres user and database that you are using. For example, change the 'development' section as follows, to add `username` and `password` configuration keys:

```yml
development:
  <<: *default
  database: mydatabase
  username: myusername
  password: mypassword
```

* Initialize the database

```
bundle exec rake db:migrate
```

* Start the application

```
rails server
```


# Documentation of Code Changes

## LibraryCloud Item API Integration

These changes allow Blacklight to use the LibraryCloud API as the backend data store, rather than a Solr index .

### [app/controllers/catalog_controller.rb](app/controllers/catalog_controller.rb)

This is the main configuration file for an installation of Blacklight. Changes in this file are:

* Swap out the Blacklight classes that interact with Solr for our own classes that interact with
the LibraryCloud API

```ruby
    ## Class for sending and receiving requests from a search index
    config.repository_class = Harvard::LibraryCloud::Repository
 
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    config.search_builder_class = Harvard::LibraryCloud::SearchBuilder
 
    ## Model that maps search index responses to the blacklight response model
    config.response_model = Harvard::LibraryCloud::Response
```

* Set the relative path to be appended to the Base URL when making API queries. In a traditional
Blacklight installation this will identify the Solr core to be used. In our case, we use it to
identify the record format (JSON + MODS) to return
```ruby
# Path which will be added to the API base url before the other API params.
config.solr_path = 'items.json'
```

* Configure the fields that Blacklight uses for display, searching, sorting, and faceting. These
need to match the fields returned by the LibraryCloud API. 
The methods and attributes used to set the fields are:
```
config.index.title_field
config.index.thumbnail_field
config.show.title_field
config.show.thumbnail_field
config.add_index_field()
config.add_show_field()
config.add_search_field()
config.add_sort_field()
config.add_facet_field()
```

* Disable autocomplete. Since the LibraryCloud API does not support autocomplete, this will result
in an error if enabled
```ruby
config.autocomplete_enabled = false
```

* The addition of a new action called `qualtricsPostRequest`. This action is routed to receive the post request made for metadata crowdsourcing from the item page. It will parse the user form's answer and send it to [qualtrics](qualtrics.com), which is the backend data collection service used. Acting as a middle man between the client side and qualtrics, this method will also send back to the user's browser whether the data collection was successful or not. 


### [app/controllers/fulltexts_controller.rb](app/controllers/fulltexts_controller.rb)

New controller generated in order to take care of the "raw text" feature. Only has one method `index` which will pipe the params received from routing (in [config/routes.rb](config/routes.rb)to generate the page using the corresponding view ([app/views/fulltexts/index.html.erb](app/views/fulltexts/index.html.erb)). According to the value of the params passed it can also generate a page indicating no ocr being present or a page indicating the drs id is incorrect. 

### [app/helpers/application_helper.rb](app/helpers/application_helper.rb)

Contains miscellaneous helper functions. 
One of which is 'generate_twitter_meta_tags' callled in [app/views/layouts/blacklight.html.erb](app/views/layouts/blacklight.html.erb). As its name implies, it will generate twitter meta tags in order for this balcklight instance to correctly be hyperlinked on a twitter post. This function will also dynamically link in the meta tags a corresponding thumbnail according to whether the current page is one about a still image content. This thumbnail is either the still image itself, or the first page in the case of multiple pages content. 

This also contains all the main functions used in order to generate the html elements related to the metadata crowdsourcing feature. Namely the function `generate_metadata_crowdsourcing_elems` which if its arguments match the crowdsourcing trigger's requirements (fetched by the helper function `retrieve_crowdsourcing_info_from_drupal_page`) will return the html tag for an "Improve this record" button as well as the html code for the modal containing the crowdsourcing options. This function is called in [app/views/catalog/_show_default.html.erb](app/views/catalog/_show_default.html.erb) and its result are stored there. Most of the other functions ins application_helper are helper function in order to achieve the metadata crowdsourcing. 



### [app/helpers/blacklight/facets_helper_behavior.rb](app/helpers/blacklight/facets_helper_behavior.rb)

Updates to support rendering custom formatted facet counts (e.g. 5.8k instead of 5,800) and custom CSS classes.
 
### [app/helpers/blacklight/catalog_helper_behavior.rb](app/helpers/blacklight/catalog_helper_behavior.rb)

Updated the method 'render_thumbnail_tag_document' so that it uses a new function 'image_tag_wout_alt'. This was done to avoid having the URN being put in the thumbnail image's alt tag. The new function is a duplicate of the built_in [function 'image_tag' from rails v. 5.1.4](https://github.com/rails/rails/blob/v5.1.4/actionview/lib/action_view/helpers/asset_tag_helper.rb) with a minor modification: the alt tag in the image generated will be an empty string in the case the _:alt_ attribute from the _options_ argument is nil.

### [app/models/solr_document.rb](app/models/solr_document.rb) 

Create a model for the document that will be used to display content in Blacklight on index and 
detail pages. Takes a MODS document from LibraryCloud and returns a flat list of fields with values.

This class is responsible for parsing all fields from the JSON response returned by the LC API. JsonPath is used to find particular nodes by path:

```ruby
raw_object = JsonPath.new('$..location..url[?(@["@access"] == "raw object")]["#text"]').first(doc)
```

### [app/models/blacklight/facet_paginator.rb](app/models/blacklight/facet_paginator.rb) 

Customize facet pagination logic to support ordering A-Z in "more" dialog with LC API.

### [config/application.rb](config/application.rb)

Allow the application to find the `Harvard::LibraryCloud` package in the `lib` directory

### [config/database.yml](config/database.yml), [config/environments/production.rb](config/environments/production.rb), and [db/schema.rb](db/schema.rb)

Changes to allow the site to be deployed to Heroku (use Postrgres instead of sqlite)

### [lib/harvard/library_cloud/repository.rb](lib/harvard/library_cloud/repository.rb)

This is the primary interface through which Blacklight interacts with Solr (or in our case, the API). It replaces 
`lib/blacklight/solr/repository.rb` which is distributed with part of the Blacklight gem. The 
code is mostly the same as that in the file it replaces, with the following changes:

* `build_connection()` returns a `Harvard::LibraryCloud::API` rather than an `RSolr` connection
* Some log statements and variable names are changed to clarify they reference the LibraryCloud API 
rather than Solr (for example `solr_response` is renamed to `api_response`)  

### [lib/harvard/library_cloud/api.rb](lib/harvard/library_cloud/api.rb)

This class handles the actual interaction with the LibraryCloud API. This includes: 

* Mapping the Blacklight request parameters to LibraryCloud API parameters. The parameters passed to this
class are the same as those passed to `RSolr` in a standard Blacklight configuration, so they need
to be altered to reflect the difference between Solr and LibraryCloud API syntax
* Adding parameters to the LibraryCloud API query to limit results to public items in DRS
* Making the actual HTTPS call to the LibraryCloud API

This class includes code which escapes special characters before passing them to LC in the method params_to_lc.

```ruby
special_chars = Regexp.escape('~!^()-[]{}\"/')
search_term = search_term.gsub(/[#{special_chars}]+/){|match| puts "\\" + match}
search_term = search_term.gsub(/ +/, " ").gsub(/&+/, "&").gsub(/\|+/, "|")
```

This class also rewrites the names of certain facet fields before passing them to LC in the method facet_query_params_to_lc. Some facets use the "_exact" version of the field name, but for other fields, such as originPlace, this doesn't work due to an LC bug. 

```ruby
if m[1] == 'subject' || m[1] == 'originPlace' || m[1] == 'seriesTitle'
  results[m[1]] = m[2]
else
  results[m[1] + '_exact'] = m[2]
end
```

### [lib/harvard/library_cloud/response.rb](lib/harvard/library_cloud/response.rb)
Parse the response received from the LibraryCloud API. Inherit from the `response.rb` provided by
Blacklight, and override certain functions as needed to handle differences between the responses
provided by LibraryCloud and Solr.

Including  `Harvard::LibraryCloud::Facets` rather than the Blacklight facet module 
ensures that facet responses are parsed correctly based on the LibraryCloud format.

### [lib/harvard/library_cloud/facets.rb](lib/harvard/library_cloud/facets.rb)
Replaces 
`lib/blacklight/solr/response/facets.rb` which is distributed with part of the Blacklight gem. The 
code is mostly the same as that in the file it replaces, with the following change:

* `facet_fields()` is changed to parse facets using the LibraryCloud format rather than the Solr
format

### [lib/harvard/library_cloud/search_builder.rb](lib/harvard/library_cloud/search_builder.rb)
Blacklight defines a processor chain that can be used to add additional fields to the query. We use
that here to add the 'search_field' parameter, which is required for the LibraryCloud API, but not Solr. We also add the 'range' field in order to support the Date facet.

## Custom Design Implementation

These changes apply a custom design to the default Blacklight installation. The home, search,
and item detail pages have been updated with the new design.

### [app/controllers/application_controller.rb](app/controllers/application_controller.rb)
Change Devise redirect URL after sign-in and sign-out to point to the search results page.

### [app/controllers/catalog_controller.rb](app/controllers/catalog_controller.rb)

* Configure the "actions" that we want to display for items in the results by removing unwanted actions
 using `config.show.document_actions.delete()` 
* Define the partials (_FILE.html.erb) that we want to include on the index and item detail pages,
in the desired order
```ruby
config.index.partials = [:thumbnail, :index_header, :index]
config.show.partials = [ :show_header, :show_original, :show]
```
* Configure the search results partials for different views. This controls what partials and fields are shown for Gallery and Masonry views.
```
config.view.gallery.partials = [:index_header]
config.view.masonry.partials = [:index]
```

* Enable the BlackLight Range Limit gem. This gem is used for the Date facet functionality.
```
include BlacklightRangeLimit::ControllerOverride
```

* Configure the user utility nav (Saved Searches, Search History, etc). This code clears the default user util nav and adds desired the nav items.

The method to clear the default nav is:
```
config.navbar.partials = {}
```

The method used to add nav items is:
```
config.add_nav_action()
```

* Disable bookmarks functionality. Because the bookmarks functionality is not ready to be used at this time, it has been removed from the utility nav and the bookmark control has been removed from search results.
This is done with using this code:
```
config.enable_bookmarks = false
```

* Set the options for the pager
```ruby
config.per_page = [12,24,48,96]
```

* Has an action  called `qualtricsPostRequest` corresonding to a post request made on the metadata crowdsourcing's form  generated in [app/views/catalog/_show_default.html.erb](app/views/catalog/_show_default.html.erb). This function parse the post request body and then use them in a post request to qualtrics. According to the success of this subsequent request, it will render back a HTTP answer to the client.



### Additional UI Enhancements

* Install the Foundation 5 framework using the `foundation-rails` gem
* Create a master SASS file at [app/assets/stylesheets/application.scss](app/assets/stylesheets/application.scss) and additional SASS files
under [app/assets/stylesheets/_*.scss](app/assets/stylesheets)
* Add Javascript for facet interactivity in [app/assets/javascripts/application.js](app/assets/javascripts/application.js)
* Add icons for the different document types at [app/assets/images/icons/*.svg](app/assets/images/icons)
* Add image assets for the home page at [app/assets/images/*.png](app/assets/images)
* Add helper class to support displaying images using the `<picture>` element at [app/helpers/images_helper.rb](app/helpers/images_helper.rb)
* Customize the default Blacklight layout in [app/views/layouts/blacklight.html.erb](app/views/layouts/blacklight.html.erb)
* Create partials under [app/views](app/views) to override the Blacklight presentation

### Notable Customized Partials

#### Facets
Update UI for facet sidebar to support interactivity and design.
* [app/views/catalog/_facet_layout.html.erb](app/views/catalog/_facet_layout.html.erb) - Update HTML and class names to support accordions.
* [app/views/catalog/_facets.html.erb](app/views/catalog/_facets.html.erb) - Update HTML to support accordions. Add CTA for Curiosity.

#### Search Form
Update UI for search form that appears in the masthead.

* [app/views/catalog/_search_form.html.erb](app/views/catalog/_search_form.html.erb) - Update HTML structure.



#### Search Results
Customize search results display.
* [app/views/catalog/_document.html.erb](app/views/catalog/_document.html.erb) - Update HTML structure.  
* [app/views/catalog/_document_list.html.erb](app/views/catalog/_document_list.html.erb) - Update HTML structure.
* [app/views/catalog/_index_default.html.erb](app/views/catalog/_index_default.html.erb) - Render unescaped HTML for field values. 
* [app/views/catalog/_search_header.html.erb](app/views/catalog/_search_header.html.erb) - Update HTML structure.
* [app/views/catalog/_search_results.html.erb](app/views/catalog/_search_results.html.erb) - Update HTML structure.
* [app/views/catalog/_zero_results.html.erb](app/views/catalog/_zero_results.html.erb) - Add help text on the "no results" page.

#### Pagination
Override the default Blacklight search results pagination links to show 10 pages at a time with links for "Previous", "Next", and "..." to jump to the next 10 pages. Removed links to "Last" page dues to LC API limitations. 

Note that Blacklight uses a gem called Kaminari for pagination.
* [app/views/catalog/_results_pagination.html.erb](app/views/catalog/_results_pagination.html.erb) - Update pagination parameters.
* [app/views/kaminari/blacklight/_page.html.erb](app/views/kaminari/blacklight/_page.html.erb) - Add "..." link to jump to the next 10 pages
* [app/views/kaminari/blacklight/_paginator.html.erb](app/views/kaminari/blacklight/_paginator.html.erb) - Add pagination logic to show pages 1-10,11-20, etc.


#### Item Details
Customized catalog item details page to include tools & related links functionality.
* [app/views/catalog/_show_default.html.erb](app/views/catalog/_show_default.html.erb)

This partial was heavily customized in order to propose new user-centered functionnalities regarding the current document. The main ruby additions were lines such as these: 

```ruby
if document[:delivery_service] == 'pds'
  #html/js code
end
```

Which allowed to dynamically generate different functionnalities according to the type of item embedded in the details page. Even though the tools & related box is present on any item details page, its download button and IIF section is only generated for single and multiple pages content (`document[:delivery_service] == 'ids'` and `document[:delivery_service] == 'pds'` respectively).

It should be noted that the download button's behavior differs between the two types of image content: 

For single image content, the download button offers the possibility to download the current image in up to four different resolutions through a dropdown. The options in this dropdown are dynamicallly generated using a for loop in such a fashion:

```ruby
size_and_labels = [[300, "Small: %d x %d px"],[800, "Medium: %d x %d px"],
                    [1200, "Large: %d x %d px"],[2400, "X-Large: %d x %d px"]]
for i in 0..size_and_labels.length-1 do
  # generates the <a> tag's attributes and content according to the image max resolution and the size_and_labels array's content
end
```

In the case of multiple pages content the download button offers a submenu which allow the user to specify a page range and email adress. This menu's behavior and interactions with the PDS are handled by a custom javascript function 'extractMessageFromEmailDLR()' included only in this case. 

Some other customisations on this page are only present in the case of a pds document: 

* The link to open the current item in Mirador included on the IIIF section. 
* The link and code related to the guided tour modal. The ruby functions generating part of this code are included in [app/helpers/application_helper.rb](app/helpers/application_helper.rb)

## Notable Gems

* [JsonPath](https://github.com/joshbuddy/jsonpath) - Provides XPath like syntax for querying JSON objects. This is used to parse responses from the LC API. Used in [app/models/solr_document.rb](app/models/solr_document.rb). 
* [Blacklight Gallery](https://github.com/projectblacklight/blacklight-gallery) - Plugin for Blacklight that supports multiple search results views (List, Gallery, and Masonry).
* [Blacklight Range Limit](https://github.com/projectblacklight/blacklight_range_limit) - Plugin for Blacklight that supports date range facets.



 
## Known Issues

* Not possible to select multiple choices within a single facet.
    * Workaround: set “single: true” on the facet_field configuration
    * Reason: LC API doesn’t handle queries on the same field correctly)
* “Autocomplete” functionality does not work
    * Workaround: disable it in the catalog_controller
    * Reason: not supported by LibraryCloud API
* Can only sort by relevance
    * Workaround: Use “relevance” as the only sort option
    * Reason: Sorting by date not supported by LibraryCloud API
* Linked metadata not searching against "_exact" fields
    * Workaround: Use LC field names without "_exact" for some fields.	
    * Reason: The "_exact" field in LC is not indexing properly for some fields, such as originPlace. There is an LC fix in progress.
* Can only paginate through 100,000 records
	* Workaround: Update pagination to remove "Last" links that jump to end of record set.
	* Reason: LC API was experiencing performance issues with returning all 6 million+ records. API was updated to limit record set to 100,000 (though search counts are still accurate).
* Bookmarks not functional. 	
	* Workaround: Hide from user interface for now. See "Disabled Functionality" below.
	* Reason: LC API method for requesting multiple documents by identifier doesn't support colons. There is a plan to fix this in the API.


## Disabled Functionality 

### Bookmarks
Out-of-the-box Blacklight includes bookmarking functionality to allow a user to save particular catalog items to their account to view later. In order to integrate this functionality with LibraryCloud, the Blacklight application needs to be able to query for multiple item identifiers in a query. The LC API support for this type of request has a bug where colons in identifiers cause the query to fail. The LC development team is currently working on a fix for this.

To enable bookmarks, edit [app/controllers/catalog_controller.rb](app/controllers/catalog_controller.rb) and set enable_bookmarks to true:
```ruby
config.enable_bookmarks = false
```

Note the existing API request for multiple identifiers uses "OR" to separate values: recordIdentifier=(LN91 OR LN93)

An upcoming enhancement to the API will support comma separated identifiers: recordIdentifier=(LN91,LN93)

The bookmarks API query syntax can be modified in the params_to_lc method of [lib/harvard/library_cloud/api.rb](lib/harvard/library_cloud/api.rb). 
```ruby
results[:recordIdentifier] = m[1].gsub('"', '')
```

To change the API request to use a comma, make the following string replacement:
```ruby
results[:recordIdentifier] = m[1].gsub('"', '').gsub(' OR ', ',') 
```


### Add items to LibraryCloud Collections 
The "Add To Collection" functionality was part of the original prototype but has been removed from the UI, though the underlying code still exists in the project for future use. 

The current plan is to implement the functionality in phases, starting with using Bookmarks. 

  
