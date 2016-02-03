You will need to install Sinatra and Mongo gems: gem install sinatra mongo

You will need to have a Mongodb instance running with a collection already created. Edit the collection name in the source code to whatever yours is called, default is profiles as this was started with OSINT in mind.

By default this runs in your local browser at 127.0.0.1 on port 4567, to access simply make the proper request to the proper route. Example:

http://127.0.0.1:4567/route/?options if defined below

You can use & to define more than one key:value in a request for any routes that show a key:value in them below

	GET /search/?<key>=<value> 	
	GET /profiles/<id> 			returns all key:value pairs in the document
	GET /profiles/<id>/?fields=<comma,separated,values> where fields are the keys whose values you want returned from the document
	GET /profiles/?				returns all documents in collection
	POST /new_profile/?<key>=<value>
	PUT /update/<id>/?<key>=<value>
	DELETE /remove/<id>