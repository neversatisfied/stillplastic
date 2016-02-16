#/usr/bin/ruby



require 'mongo'
require 'sinatra'
require 'json'
require 'uuidtools'
require 'rubygems'
require 'webrick/httputils'


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

	def set_collection coll	
		Sinatra::Base.set :mongo_db, settings.db[:"#{coll}"]				
	end

	def extract_count params
		if params.has_key?("count")
			temp_count = 1 
		else
			temp_count = 0
		end
		return temp_count	

	end
	
	def extract_projection params
		if params.has_key?("project")
			temp_proj = Array(params[:project].to_s.split(","))
			projection_s = Hash.new
			projection_s[:_id] = 0
			temp_proj.each do |val|
				projection_s[val.to_sym] = 1
			end
			return projection_s
		else
			return
		end
	end

	def extract_limit params
		if params.has_key?("limit")
			limit = params[:limit].to_i
			limit
		else
			limit = 0
			limit
		end
	end
	
	def extract_query params
		if params[:q]
			query = JSON.parse(params[:q])
			query
		else
			nil
		end
	end
 	
	def build_query params
		if params.nil?
			status 400
			body "Invalid request, please refer to the API docs"
		else
			count = extract_count(params)
			lim = extract_limit(params)
			temp_q = extract_query(params)
			s_proj = extract_projection(params)
			if s_proj.nil?
				results = settings.mongo_db.find(temp_q).limit(lim).to_a
			
			else
				results = settings.mongo_db.find(temp_q).projection(s_proj).limit(lim).to_a
			end
			i_count = Hash.new
                        i_count["count"] = results.count().to_s
			results.unshift(i_count)
			(results || {}).to_json	
		end	
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

get '/:collection/count/' do
	document = settings.mongo_db.find.count()
	(document || {}).to_json
end

get '/:collection/recent/:count/' do
	document = settings.mongo_db.find.limit(params[:count].to_i).sort(:_id => -1).to_a
	puts document.to_json
	(document || {}).to_json
end

get '/:collection/search/?*' do
	content_type :json
	build_query(params)
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
