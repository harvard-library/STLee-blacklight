# README

This repository contains a Blacklight instance that uses the Harvard LibraryCloud Item API as a backend in place of
the standard Solr backend. It also allows adding items to the LibraryCloud collections using the 
Collections API.

It also contains a custom "skin" for the discovery interface.  

Demo site: https://ancient-peak-25869.herokuapp.com

# Deployment

## Red Hat

TK

## Heroku

* Create a new application on Heroku
* If not already installed, install the Heroku command-line tools as 
per https://devcenter.heroku.com/articles/heroku-command-line and login to your Heroku account
* On the "Deploy" tab for your application, select "Heroku Git" as the deployment method
* Clone this repository
* Add the Heroku repository as a remote

``
heroku git:remote -a [MY APPLICATION NAME]
``
* Push the code to Heroku

``
git push heroku master
``
* On the "Settings" tab add a new Config Variable named `LC_API_KEY` with the value of your 
LibraryCloud API key. (This is only required for the "Add to Collection" functionality)
   

    
# Implementation Notes

## Guiding Principles


## Approach



# Documentation of code changes

## Use the LibraryCloud Item API

###`app/controllers/catalog_controller.rb`

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

 

### Apply custom design

`app/controllers/catalog_controller.rb`

* Configure the "actions" that we want to display for items in the results by removing unwanted actions
(`config.show.document_actions.delete()` 

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

### Add items to LibraryCloud Collections

`app/controllers/catalog_controller.rb`

* Include the `Harvard::LibraryCloud::Collections` module to handle the "Add to Collection" 
functinality, so Blacklight can find it
```ruby
include Harvard::LibraryCloud::Collections
``` 
* Add the "Add to Collection" action
```ruby
add_show_tools_partial(:add_to_collection, define_method: false)
```


 
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