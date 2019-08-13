class FulltextsController < ApplicationController

	include ApplicationHelper

	def index
		if params[:id] and params[:id] =~ /\A\d+\Z/ then #way to test if the id is numeric
			hasocr  = retrieve_hasocr_info params[:id]
			if hasocr
				render "index", :locals => {:drs_id => params[:id]}
			else
				render "_no_ocr"
			end
		else
			render "wrong_id"
		end
	end
end