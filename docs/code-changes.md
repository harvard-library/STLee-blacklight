# Documentation of Code Changes

## Use the LibraryCloud Item API

These changes allow Blacklight to use the LibraryCloud API as the backend data store, rather than a Solr index .

### [app/controllers/catalog_controller.rb](../app/controllers/catalog_controller.rb)

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

### [app/helpers/application_helper.rb](../app/helpers/application_helper.rb)

Contains miscellaneous helper functions
 
### [app/models/solr_document.rb](../app/models/solr_document.rb) 

Create a model for the document that will be used to display content in Blacklight on index and 
detail pages. Takes a MODS document from LibraryCloud and returns a flat list of fields with values.

### [config/application.rb](../config/application.rb)

Allow the application to find the `Harvard::LibraryCloud` package in the `lib` directory

### [config/database.yml](../config/database.yml), [config/environments/production.rb](../config/environments/production.rb), and [db/schema.rb](../db/schema.rb)

Changes to allow the site to be deployed to Heroku (use Postrgres instead of sqlite)

### [lib/harvard/library_cloud/repository.rb](../lib/harvard/library_cloud/repository.rb)

This is the primary interface through which Blacklight interacts with Solr (or in our case, the API). It replaces 
`lib/blacklight/solr/repository.rb` which is distributed with part of the Blacklight gem. The 
code is mostly the same as that in the file it replaces, with the following changes:

* `build_connection()` returns a `Harvard::LibraryCloud::API` rather than an `RSolr` connection
* Some log statements and variable names are changed to clarify they reference the LibraryCloud API 
rather than Solr (for example `solr_response` is renamed to `api_response`)  

### [lib/harvard/library_cloud/api.rb](../lib/harvard/library_cloud/api.rb)

This class handles the actual interaction with the LibraryCloud API. This includes: 

* Mapping the Blacklight request parameters to LibraryCloud API parameters. The parameters passed to this
class are the same as those passed to `RSolr` in a standard Blacklight configuration, so they need
to be altered to reflect the difference between Solr and LibraryCloud API syntax
* Adding parameters to the LibraryCloud API query to limit results to public items in DRS
* Making the actual HTTPS call to the LibraryCloud API

### [lib/harvard/library_cloud/response.rb](../lib/harvard/library_cloud/response.rb)
Parse the response received from the LibraryCloud API. Inherit from the `response.rb` provided by
Blacklight, and override certain functions as needed to handle differences between the responses
provided by LibraryCloud and Solr.

Including  `Harvard::LibraryCloud::Facets` rather than the Blacklight facet module 
ensures that facet responses are parsed correctly based on the LibraryCloud format.

### [lib/harvard/library_cloud/facets.rb](../lib/harvard/library_cloud/facets.rb)
Replaces 
`lib/blacklight/solr/response/facets.rb` which is distributed with part of the Blacklight gem. The 
code is mostly the same as that in the file it replaces, with the following change:

* `facet_fields()` is changed to parse facets using the LibraryCloud format rather than the Solr
format

### [lib/harvard/library_cloud/search_builder.rb](../lib/harvard/library_cloud/search_builder.rb)
Blacklight defines a processor chain that can be used to add additional fields to the query. We use
that here to add the 'search_field' parameter, which is required for the LibraryCloud API, but not Solr

## Apply custom design

These change apply a custom design to the default Blacklight installation. The home, search,
and item detail pages have been updated with the new design.

### [app/controllers/catalog_controller.rb](../app/controllers/catalog_controller.rb)

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

* Create a master SASS file at [app/assets/stylesheets/application.scss](../app/assets/stylesheets/application.scss) and additional SASS files
under [app/assets/stylesheets/_*.scss](../app/assets/stylesheets)
* Add icons for the different document types at [app/assets/images/icons/*.svg](../app/assets/images/icons)
* Add image assets for the home page at [app/assets/images/*.png](../app/assets/images)
* Add helper class to support displaying images using the `<picture>` element at [app/helpers/images_helper.rb](../app/helpers/images_helper.rb)
* Create partials under [app/views](../app/views) to override the default Blacklight layout
