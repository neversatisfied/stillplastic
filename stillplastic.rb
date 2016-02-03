#/usr/bin/ruby
 
require 'mongo'
require 'sinatra'
require 'json'
require 'uuidtools'

configure do
	db = Mongo::Client.new(['127.0.0.1:27017'], :database => 'data')
	set :db, db
end

def set_uuid()
	uuid = UUIDTools::UUID.random_create
	return uuid.to_s
end
 
helpers do

	def set_collection coll	
		Sinatra::Base.set :mongo_db, settings.db[:"#{coll}"]				
	end

	def object_id val
		begin
			BSON::ObjectId.from_string(val)
		rescue BSON::ObjectId::Invalid
			nil
		end
	end
	
	def profile_query params 
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
				request.params.keys.each do |k|
					document = settings.mongo_db.find({"#{k}" => /#{request.params[k]}/}).projection(projection_s).to_a
					results.push(document)
				end
				results[0].to_json
			else
				request.params.keys.each do |k|
					document = settings.mongo_db.find({ "#{k}" => /#{request.params[k]}/}).to_a
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
		settings.mongo_db.find(:id => id).to_a.to_json	
	end
end

post '/:collection/new_record/?' do
	content_type :json
	set_collection(params[:collection])
	db = settings.mongo_db
	request.params[:id] = set_uuid()
	result = db.insert_one request.params 
	redirect "http://127.0.0.1:4567/"+ params[:collection]+"/" + request.params[:id] +"/"
end
 
get '/collections/?' do
	content_type :json
	settings.db.database.collection_names.to_json
end

get '/:collection/' do	
	set_collection(params[:collection])
	settings.mongo_db.find.to_a.to_json
end 
 
get '/:collection/search/?' do
	content_type :json
	set_collection(params[:collection])
	search_query(params)
end

get '/:collection/:id/?' do
	content_type :json
	set_collection(params[:collection])
	profile_query(params)
end

put '/:collection/update/:id/?' do
	content_type :json
	set_collection(params[:collection])
	update_query(params)
end
 
delete '/:collection/remove/:id/' do
	content_type :json
	set_collection(params[:collection])
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
