#/usr/bin/ruby
 
require 'mongo'
require 'sinatra'
require 'json'
require 'uuidtools'

configure do
	db = Mongo::Client.new(['127.0.0.1:27017'], :database => 'data')
	set :mongo_db, db[:data]
end

def set_uuid()
	uuid = UUIDTools::UUID.random_create
	return uuid.to_s
end
 
helpers do

	def object_id val
		begin
			BSON::ObjectId.from_string(val)
		rescue BSON::ObjectId::Invalid
			nil
		end
	end
	
	def profile_query params 
		#params.delete("splat")
		#params.delete("captures")
		if params.nil?
			{}.to_json
		else
			id = params[:id]
			if params[:fields]
				fields = Array(params[:fields].to_s.split(","))
				projection_s = Hash.new
				fields.each do |val|
					projection_s[:"#{val}"] = 1
				end
				document = settings.mongo_db.find(:id => id).projection(projection_s).to_a.to_json
			else
				document = settings.mongo_db.find(:id => id).to_a.first
				(document || {}).to_json
			end
		end
	end
 
	def search_query params
		results = Array.new
		if params.nil?
			{}.to_json
		else
			id = params[:id]
			if params[:fields]
				fields = Array(params[:fields].to_s.split(","))
				projection_s = Hash.new
				fields.each do |val|
					projection_s[:"#{val}"] = 1
				end
				params.delete("fields")
				params.keys.each do |k|
					document = settings.mongo_db.find({"#{k}" => /#{params[k]}/}).projection(projection_s).to_a
					results.push(document)
				end
				results[0].to_json
			else
				params.keys.each do |k|
					document = settings.mongo_db.find({ "#{k}" => /#{params[k]}/}).to_a
					results.push(document)
				end
				results[0].to_json	
			end
		end
	end

	def update_query params
		id = params[:id]
		request.params.keys.each do |k|
			settings.mongo_db.find(:id => id).update_one("$set" => { "#{k}" => "#{request.params[k]}"})
		end
		profile_query(id)	
	end
end

get '/collections/?' do
	content_type :json
	settings.mongo_db.database.collection_names.to_json
end
 
get '/profiles/?' do
	content_type :json
	settings.mongo_db.find.to_a.to_json
end

get '/profiles/:id/?' do
	content_type :json
	profile_query(params)
end
 
get '/search/?' do
	content_type :json
	search_query(params)
end

post '/new_collection/:collection/?' do
	content_type :json
	#settings.mongo_db.create
	db = Mongo::Client.new([ '127.0.0.1:27017'], :database => 'data')
	collection = db[:"#{params[:collection]}", :capped => false]
	collection.create
	db.database.collection_names.to_json
end
 
post '/new_profile/?' do
	content_type :json
	db = settings.mongo_db
	params[:id] = set_uuid()
	result = db.insert_one params 
	redirect "http://127.0.0.1:4567/profiles/" + params[:id]
end
 
put '/update/:id/?' do
	content_type :json
	update_query(params)
end
 
delete '/remove/:id/?' do
	content_type :json
	db = settings.mongo_db
	id = params[:id]
	documents = db.find(:id => id)
	if !documents.to_a.first.nil?
		documents.find_one_and_delete
		{:success => true}.to_json
	else
		{:success => false}.to_json
	end
end
