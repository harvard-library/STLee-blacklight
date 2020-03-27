# Known Issues

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
