#/usr/bin/ruby



require 'mongo'
require 'sinatra'
require 'json'
require 'uuidtools'
require 'rubygems'



configure do
	db = Mongo::Client.new(['127.0.0.1:27017'], :database => 'data')
	set :db, db
	set :port, 4567
	set :bind, '0.0.0.0'
	set :environment, 'production'
	file = File.new("/var/log/sinatra.log", 'a+')
	file.sync = true
	use Rack::CommonLogger, file
end


def set_uuid()
	uuid = UUIDTools::UUID.random_create
	uuid.to_s
end
 
helpers do

	def extract_limit params
		if params.has_key?("limit")
			limit = params[:limit].to_i
			limit
		else
			limit = 50
			limit
		end
	end
	
	def extract_query params 
		if params.has_key?("q")
			if params[:q].include? ","
	 			query = Hash[*params[:q].split(',')]
			else
				query = {}
				query[params[:q]] = params[:q]
				query
			end 
		else
			nil
		end
	end
	
	def extract_condition params
		if params.has_key?("condition")
			condition = Array(params[:condition].split(','))
			condition
		else
			nil
		end
	end

	def set_collection coll	
		Sinatra::Base.set :mongo_db, settings.db[:"#{coll}"]				
	end
	
	def profile_query params 
		id = params[:id]
		result = extract_projection(params)
		if result.nil?
			document = settings.mongo_db.find(:id => id).to_a.first
			(document || {}).to_json
		else
			document = settings.mongo_db.find(:id => id).projection(result).to_a.first
			(document || {}).to_json
		end
	end
 
	def search_query params
		#results = Array.new
		if params.nil?
			status 400
			body "Invalid request, please refer to the API docs"
		else
			field_query = extract_query(params)
			puts field_query
			lim = extract_limit(params)
			cond_query = extract_condition(params)
			
			val = field_query.keys.first
			if cond_query.nil?
				results = settings.mongo_db.find(field_query).limit(lim).to_a	
				(results || {}).to_json
			else
				new_l = cond_query[0]
				if cond_query[0] == "$exists" && cond_query[1] == "true"
					cond_val = 1
				elsif cond_query[0] == "$exists" && cond_query[1] == "false"
					cond_val = 0
				else
					cond_val = cond_query[1]
					
				end

				results = settings.mongo_db.find( {val.to_sym => {new_l.to_sym => cond_val}}).to_a
				(results || {}).to_json
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
		request.body.rewind
		json_s = JSON.parse request.body.read
		if json_s.has_key?("results")
			attackers = []
			json_s["results"].each do |attacker|
				attacker["id"] = set_uuid()
				attackers.push attacker
				puts attacker
			end
			db.insert_many attackers
		else
			json_s["id"] = set_uuid()
			db.insert_one json_s
			json_s.to_json	
		end

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
