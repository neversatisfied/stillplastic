#/usr/bin/ruby
 
require 'mongo'
require 'sinatra'
require 'json'
require 'uuidtools'

set :bind, '0.0.0.0'

configure do
	db = Mongo::Client.new(['127.0.0.1:27017'], :database => 'data')
	set :db, db
end

def set_uuid()
	uuid = UUIDTools::UUID.random_create
	uuid.to_s
end
 
helpers do
	def fields_parse(params)
		if params.nil?
			{}.to_json
		else
			id = params[:id]
			if params[:fields]
				fields = Array(params[:fields].to_s.split(","))
				projection_s = Hash.new
				fields.each do |val|
					projection_s[val.to_sym] = 1
				end
				return projection_s	
			else
				return	
			end
		end
	end

	def set_collection coll	
		Sinatra::Base.set :mongo_db, settings.db[:"#{coll}"]				
	end
	
	def profile_query params 
		id = params[:id]
		result = fields_parse(params)
		if result.nil?
			document = settings.mongo_db.find(:id => id).to_a.first
			(document || {}).to_json
		else
			document = settings.mongo_db.find(:id => id).projection(result).to_a.first
			(document || {}).to_json
		end
	end
 
	def search_query params
		results = Array.new
		id = params[:id]
		s_proj = fields_parse(params)
		if s_proj.nil?
			request.params.keys.each do |k|
				document = settings.mongo_db.find({ "#{k}" => /#{request.params[k]}/}).to_a
				results.push(document)
			end
		else
			request.params.keys.each do |k|
				document = settings.mongo_db.find({"#{k}" => /#{request.params[k]}/}).projection(s_proj).to_a
				results.push(document)
			end
		end
		(results[0].to_json || {}).to_json
	end

	def update_query params
		id = params[:id]
		request.params.keys.each do |k|
			settings.mongo_db.find(:id => id).update_one("$set" => { "#{k}" => "#{request.params[k]}"})
		end
		settings.mongo_db.find(:id => id).to_a.to_json	
	end
end

before '/:collection/*' do
	pass if %w[collections].include? request.path_info.split('/')[1]
	set_collection(params[:collection])
end

get '/collections/?' do
	content_type :json
	document = settings.db.database.collection_names.to_a
	(document || {}).to_json
end

post '/:collection/new_record/?' do
	content_type :json
	set_collection(params[:collection])
	db = settings.mongo_db
	if request.params.empty?
		attackers = []
		json_s = JSON.parse request.body.read
		json_s["results"].each do |attacker|
			attacker["id"] = set_uuid()
			attackers.push attacker
			puts attacker
		end
		db.insert_many attackers
		attacker.to_json
	else
		request.params[:id] = set_uuid()
		db.insert_one request.params	
		redirect "http://172.21.3.254:4567/" + params[:collection] + "/" + request.params[:id] +"/"
	end
	
end

get '/:collection/' do	
	document = settings.mongo_db.find.to_a
	(document || {}).to_json
end 

get '/:collection/search/?' do
	content_type :json
	search_query(params)
end

get '/:collection/:id/?' do
	content_type :json
	profile_query(params)
end

put '/:collection/update/:id/?' do
	content_type :json
	update_query(params)
end
 
delete '/:collection/remove/:id/' do
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
