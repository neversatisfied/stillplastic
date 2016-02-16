#StillPlastic
A Ruby+Sinatra+Mongo metadata collection framework



You will need to install Sinatra and Mongo and Thin(webserver) gems: gem install sinatra mongo thin

You will need to have a Mongodb instance running with a collection already created. Edit the collection name in the source code to whatever yours is called, default is profiles as this was started with OSINT in mind.

By default this runs in your local browser at 127.0.0.1 on port 4567, to access simply make the proper request to the proper route. Example:

http://127.0.0.1:4567/collection_name/route/?<options> if defined below

You can use & to define more than one key:value in a request for any routes that show a key:value in them below

	GET /collections/				returns a list of all available collections
	GET /<collection>/search/?q=<mongodb query>&<optional parameters>
		Parameters allowed are: fields to search, condition to compare, and limit to return 
			
		Optional Parameters:
			&limit=X		limits results to X
			&project=Z,A		returns only fields with key name matching Z and A for the query
			

		-Limit defaults to 0, which is all matching documents. Be sure to specify a limit if you have a loosely defined query so as to not stress the DB
		-The query must be in the proper mongodb query format, no spaces and "" around all keys/values.
		-Projection by default has the _id field set to 0, which doesn't return it. If you would like the _id field then add _id to the projection arguments
		
	
		{"<one>": "<one.five>" {"two": "three"}, {"four": "five"}}&option1&option2&option3
			This is the basic synatx, where:
				<one> is a key name, or a logical operator https://docs.mongodb.org/v3.0/reference/operator/query/#logical
				<one.five> is the key value, if your using any further refinements to the query then skip this field and go straight to two
				<two> is a query selector, https://docs.mongodb.org/v3.0/reference/operator/query/#query-selectors or an element https://docs.mongodb.org/v3.0/reference/operator/query/#element or an evaluation https://docs.mongodb.org/v3.0/reference/operator/query/#evaluation
				<three> is the value the query selector or element is being compared too
				<four> & <five> optional values, only used if performing a logical operation (check examples below)
		Examples:
			{"name":"test"}
			{"name":"test"}
				This would return all documents with a field "name" whose value is "test". 
				SQL equivalent: Select name, test from COLLECTION where name = "test";
			{"$or":{"name":"test"},{"name","bob"}}
				This would return all documents with a field "name" whose value is either "test" or "bob"
				SQL equivalent: Select * from COLLECTION where name = "test" OR name = "bob";
			{name: {"$regex": /test/}}
			{"name":{"$regex":"test"}}
				This would return all documents with a field "name" that contain the value "test"
					-So test, testme, iamatest, please dont test, would all be returned
				SQL equivalent: Select * from COLLECTION where name LIKE "test";
			{"name":{"$regex":"^(?:(?!test).)*$","$options":"m"}}&project=server
				This would return all documents with a field where the name does not containt the value "test"
				SQL equivalent: Select * from COCLLECTION where name !LIKE "test";
					-you must have the $options:m portion to do not matching regex, maybe in the future I will build this into a function to make it easier to query
			{"name":{"$ne":"test"}}
				This would return all documents where the field "name" do not equal "test"
					-test would not be returned, however testme would still count.


	GET /<collection>/recent/<count>/		returns the latest X documents, defined by count 
	GET /<collection>/<id>/ 			returns all key:value pairs in the document
	GET /<collection>/<id>/?fields=<comma,separated,values> where fields are the keys whose values you want returned from the document
	GET /<collection>				returns all documents in collection
	POST /<collection>/new_record/?<key>=<value>
	PUT /<collection>/update/<id>/?<key>=<value>
	DELETE /<collection>/remove/<id>


The idea is that when you store metadata in the database, your POST request will define which collection it belongs in. For example, let's say you are collecting information for user profile creation by scraping a forums user's list. You would then post the data in something like the "profiles" collection: http://127.0.0.1:4567/profiles/new_record/?forum=<value>&user=<value>&email=<value>
If you then were scraping data from chat logs on irc, you would put it in the "irc_logs" collection. One could then write a tool to go through and find documents in the "irc_logs" collection with the username as from the "profiles" collection and create a new document with the same :id as the document from the "profiles" collection with the relevant chat logs either embedded in the new document, or a reference to the :id of all documents in the "irc_logs" collection that contain this username. This is just an example of how you can use the data, this project is solely focused on storing the data and creating a usable API with easy to understand routes so that you can then connect your data however you would like.
