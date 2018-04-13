# README

This repository contains a Blacklight instance that uses the Harvard LibraryCloud Item API as a backend in place of
the standard Solr backend. It also allows adding items to the LibraryCloud collections using the 
Collections API.

It also contains a custom "skin" for the discovery interface.  

Demo site: https://ancient-peak-25869.herokuapp.com

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
   
## Ubuntu

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

* Install Solr for Blacklight

(This may not actually be necessary, since we're not using Solr)

```sh
gem install solr_wrapper
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

## Use the LibraryCloud Item API

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

### [app/helpers/application_helper.rb](app/helpers/application_helper.rb)

Contains miscellaneous helper functions
 
### [app/models/solr_document.rb](app/models/solr_document.rb) 

Create a model for the document that will be used to display content in Blacklight on index and 
detail pages. Takes a MODS document from LibraryCloud and returns a flat list of fields with values.

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
that here to add the 'search_field' parameter, which is required for the LibraryCloud API, but not Solr

## Apply custom design

These change apply a custom design to the default Blacklight installation. The home, search,
and item detail pages have been updated with the new design.

### [app/controllers/catalog_controller.rb](app/controllers/catalog_controller.rb)

* Configure the "actions" that we want to display for items in the results by removing unwanted actions
 using `config.show.document_actions.delete()` 
* Define the partials (_FILE.html.erb) that we want to include on the index and item detail pages,
in the desired order
```ruby
config.index.partials = [:thumbnail, :index_header, :index]
config.show.partials = [ :show_header, :show_original, :show]
```
* Set the options for the pager
```ruby
config.per_page = [12,24,48,96]
```

### Additional steps to apply the design

* Install the Foundation 5 framework using the `foundation-rails` gem
* Create a master SASS file at [app/assets/stylesheets/application.scss](app/assets/stylesheets/application.scss) and additional SASS files
under [app/assets/stylesheets/_*.scss](app/assets/stylesheets)
* Add icons for the different document types at [app/assets/images/icons/*.svg](app/assets/images/icons)
* Add image assets for the home page at [app/assets/images/*.png](app/assets/images)
* Add helper class to support displaying images using the `<picture>` element at [app/helpers/images_helper.rb](app/helpers/images_helper.rb)
* Create partials under [app/views](app/views) to override the default Blacklight layout


## Add items to LibraryCloud Collections (Item Detail Page)

Create an action that allows adding items to collections through the LibraryCloud Collections API.

### [app/controllers/catalog_controller.rb](app/controllers/catalog_controller.rb)

* Include the `Harvard::LibraryCloud::Collections` module to handle the "Add to Collection" 
functinality, so Blacklight can find it
```ruby
include Harvard::LibraryCloud::Collections
``` 
* Add the "Add to Collection" action
```ruby
add_show_tools_partial(:add_to_collection, define_method: false)
```

### [lib/harvard/library_cloud/collections.rb](lib/harvard/library_cloud/collections.rb)

* Define method `add_to_collection` which is called by BlackLight when the 'Add to Collection' dialog is displayed
* Define method `add_to_collection_action` which submits one or more items to be added to a LibraryCloud collection
* Define method `add_to_collection_solr_document_path` which is called by BlackLight to define the URL to invoke
the "Add to Collection" action
* Define methd `available_collections` which retrives a list of collections to which an item can be added 

### [app/views/catalog/add_to_collection.html.erb](app/views/catalog/add_to_collection.html.erb)

Modal for displaying the "Add To Collection" form

### [app/views/catalog/_add_to_collection_form.html.erb](app/views/catalog/_add_to_collection_form.html.erb)

Partial that renders the "Add to Collection Form"
 
### [app/views/catalog/add_to_collection_success.html.erb](app/views/catalog/add_to_collection_success.html.erb)

Modal for displaying the "Succes" message after an item is added to a collection
 
## Add items to LibraryCloud Collections (Search Results Page) 

Allow users to add items to the collections in bulk from the search results page.
 
### [app/controllers/catalog_controller.rb](app/controllers/catalog_controller.rb)

 * Add the "Add to Collection" action to items in the search results
 ```ruby
 add_results_document_tool(:add_to_collection, define_method: false)
 ```

### [app/views/catalog/_index_default.html.erb](app/views/catalog/_index_default.html.erb)

Add display of document actions to the bottom of each individual item in the search results

### [app/views/catalog/_add_to_collection_index.html.erb](app/views/catalog/_add_to_collection_index.html.erb)

Define a partial for the 'add to collection on the index page' action, that will be included 
from [app/views/catalog/_index_default.html.erb](app/views/catalog/_index_default.html.erb).   

This is basically just a checkbox with no smarts.

### [app/views/catalog/_add_to_collection_index_action.html.erb](app/views/catalog/_add_to_collection_index_action.html.erb)

Define a partial that can include the actual "Add to Collection" button for the search results page, along with a 
"Select all" checkbox. This partial is included in the search results sidebar 
([app/views/catalog/_search_sidebar.html.erb](app/views/catalog/_search_sidebar.html.erb))
 
### CSS and Javascript to handle selecting checkboxes

We use Javascript to dynamically update the form submit URL for the "Add to Collection" action in the
[app/views/catalog/_add_to_collection_index_action.html.erb](app/views/catalog/_add_to_collection_index_action.html.erb)
partial. And a bit of CSS to make it look better. The relevant files are:

* [app/assets/javascripts/add_multiple.js](app/assets/javascripts/add_multiple.js)
* [app/assets/stylesheets/_collections.scss](app/assets/stylesheets/_collections.scss)
  
 
## Known Issues

* Not possible to select multiple choices within a single facet.
    * Workaround: set “single: true” on the facet_field configuration
    * Reason: LC API doesn’t handle queries on the same field correctly)
* “More” option for facets is not enabled.
    * Workaround: do not specify a “limit” on the facet_field configuration
    * Reason: Not implemented
* “Autocomplete” functionality does not work
    * Workaround: disable it in the catalog_controller
    * Reason: not supported by LibraryCloud API
* Can only sort by relevance
    * Workaround: Use “relevance” as the only sort option
    * Reason: Sorting by date not supported by LibraryCloud API
* When adding an item to a collection, all collections are displayed as options, including those that the current "user" (API key) doesn't have permission to change
    * Workaround: Use an admin API key to allow adding to any collection 
    * Reason: Collections API does not allow filtering collections by owner
