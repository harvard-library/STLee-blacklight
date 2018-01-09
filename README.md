# README

Blacklight instance running against the LibraryCloud API

Demo: https://ancient-peak-25869.herokuapp.com

## Known Issues

* **Resources with ID's that contains a period cannot be displayed, and show an error page**
    * Reason: Blacklight assumes that ID's do not contain a period
    * Fix: Configure Blacklight to accept ID's with a period
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
    
## Technical Design issues

It would be more consistent with the BlackLight architecture to replace the SolrDocument being used for the response with our own document. Our current approach is to massage the data in a custom Response before creating a SolrDocument. 