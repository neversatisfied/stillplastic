#StillPlastic
A Ruby+Sinatra+Mongo metadata collection framework



You will need to install Sinatra and Mongo gems: gem install sinatra mongo

You will need to have a Mongodb instance running with a collection already created. Edit the collection name in the source code to whatever yours is called, default is profiles as this was started with OSINT in mind.

By default this runs in your local browser at 127.0.0.1 on port 4567, to access simply make the proper request to the proper route. Example:

http://127.0.0.1:4567/collection_name/route/?<options> if defined below

You can use & to define more than one key:value in a request for any routes that show a key:value in them below

	GET /collections/				returns a list of all available collections
	GET /<collection>/search/?<parameters>
		Parameters allowed are: fields to search, condition to compare, and limit to return 
			-Limit default to 50, specify 0 to return all documents that match
			-Allowed conditions are:
				$exists,(true|false)
				$eq,(value)
				$ne,(value)
				$gt,(value)
				$gte,(value)
				$lt,(value)
				$lte,(value)
			Example query: http://127.0.0.1:4567/profiles/search/?q=hunter&condition=$exists,true&limit=0
				-This would return all documents that have a field with a key of "hunter"
				-If using the condition's option then it will ignore any comma separated values in the q parameter at this point in time
			Example query: http://127.0.0.1:4567/profiles/search/?q=name,hunter
				-This would return the first 50 docs with a key "name" and a value containing "hunter"
	
	GET /<collection>/recent/<count>/		returns the latest X documents, defined by count 
	GET /<collection>/<id>/ 			returns all key:value pairs in the document
	GET /<collection>/<id>/?fields=<comma,separated,values> where fields are the keys whose values you want returned from the document
	GET /<collection>				returns all documents in collection
	POST /<collection>/new_record/?<key>=<value>
	PUT /<collection>/update/<id>/?<key>=<value>
	DELETE /<collection>/remove/<id>


The idea is that when you store metadata in the database, your POST request will define which collection it belongs in. For example, let's say you are collecting information for user profile creation by scraping a forums user's list. You would then post the data in something like the "profiles" collection: http://127.0.0.1:4567/profiles/new_record/?forum=<value>&user=<value>&email=<value>
If you then were scraping data from chat logs on irc, you would put it in the "irc_logs" collection. One could then write a tool to go through and find documents in the "irc_logs" collection with the username as from the "profiles" collection and create a new document with the same :id as the document from the "profiles" collection with the relevant chat logs either embedded in the new document, or a reference to the :id of all documents in the "irc_logs" collection that contain this username. This is just an example of how you can use the data, this project is solely focused on storing the data and creating a usable API with easy to understand routes so that you can then connect your data however you would like.
