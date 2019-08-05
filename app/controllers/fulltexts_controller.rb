class FulltextsController < ApplicationController
	def index
		if params[:id]
			render "index", :locals => {:drs_id => params[:id]} 
		end
	end
end