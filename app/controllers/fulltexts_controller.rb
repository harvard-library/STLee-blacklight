class FulltextsController < ApplicationController

	include ApplicationHelper

	def index
		#this will separate the different arguments that can be found on the url (drs id and catalog id namely)
		url_paths = params[:path].split('/', 2)
		drs_id = url_paths[0]
		#using the fact that hash returns nil when accessed somewhere not indexed.
		catalog_id = url_paths[1]
		if drs_id and drs_id =~ /\A\d+\Z/ then #way to test if the id is numeric
			hasocr  = retrieve_hasocr_info drs_id
			if hasocr
				render "index", :locals => {:drs_id => drs_id, :catalog_id => catalog_id}
			else
				render "_no_ocr"
			end
		else
			render "wrong_id"
		end
	end
end