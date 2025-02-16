extends Node
# Declare the HTTPRequest variable
var http_request : HTTPRequest
var user_id = 4 # id of the current user, is set to one if user is a guest
var text_url_extention_from_save = {"text":null, "url":null, "ext": null, "worked": false}
var texture_from_get_image = false
var extention
var sign_up_worked = 1 #flag value checking sign up
# -1 = failed,  1 = worked,  -2 = user already exists,   -3 = user_id not found,  -4 = bad user or pass  
const BASE_URL = "https://compsciia-production.up.railway.app/" # base of the API's url

func new_http(completed_func): # creates a new http request object
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, completed_func))
	return http_request
	
func upload_user(username: String, salt: String, hashed_password: String): # upload user HTTP request
	var url = BASE_URL + "users" # url of this endpoint in the server
	var http_request = new_http("_on_upload_user_request_completed") # create the http object
	# create and stringify the data for the request
	var data = {
		"username": username,
		"salt": salt,
		"hashed_password": hashed_password
	}
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]  # Set the correct content type for JSON
	# Make the POST request to the server with the data
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK: # if there is an error
		print("Error sending request: %s" % error)  # Log error if the request fails
		user_id = 1 # keep user as guest and use the sign_up-worked flag 
		sign_up_worked = -1
	await http_request.request_completed # wait for a repsonse, and return if it worked
	return sign_up_worked
# Callback for when the request completes

func _on_upload_user_request_completed(_result, response_code, _headers, body): # when the request is completed for uploading a user
	if response_code == 201: # successfully sent code
		print("User data sent successfully!")  # Log success message
		# Convert the response body to a string before parsing
		var response_str = body.get_string_from_utf8()
		# Parse the string into JSON using json instance
		var json : JSON
		json = JSON.new()
		var error = json.parse(response_str)
		if error == OK:  # no error
			var parsed_string_json = JSON.parse_string(response_str)
			var inserted_id = parsed_string_json["insertedId"]
			print("Inserted ID: %d" % inserted_id)  # Log inserted ID
			user_id = inserted_id # change the user to the logged in user
			sign_up_worked = 1
		else:
			print("Error parsing response JSON: %d" % error)  # Log the error code
			sign_up_worked = -1
			user_id = 1
	elif response_code == 409: # user exists error code
		print("User Already Exists. Response code: %d" % response_code)  # Log failure with response code
		user_id = 1 # keep as guest and show sign up didn't work
		sign_up_worked = -2
	else:
		print("Error. Response code: %d" % response_code)	
		user_id = 1 # keep as guest and show sign up didn't work 
		sign_up_worked = -1

func login(username: String, password: String): # log in user http reuqest
	var http_request = new_http("_on_login_request_completed") # create the http request object and connect to the completed function
	var url = BASE_URL + "login" # login url endpoint

	# Data to send in the request body, converted to json format
	var data = {
		"username": username,
		'password': password
	}
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]  # Set the correct content type for JSON

	# Make the POST request to the server with the data
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK: # error sending data
		print("Error sending request: %s" % error)  # Log error if the request fails
		sign_up_worked = -1 # return that the sign up didn't work
	await http_request.request_completed # wait for the request to be completed
	return sign_up_worked # return if it worked or not

func _on_login_request_completed(_result, response_code, _headers, body): # login request is completed
	if response_code == 200: # successfull login
		print("successful login")
		var response_str = body.get_string_from_utf8() # turn to a string
		# Create a new JSON instance to parse the response string
		var json = JSON.new()
		var error = json.parse(response_str)
		if error == OK:  # there is no error
			var parsed_json = JSON.parse_string(response_str)  # Parsed JSON as a Dictionary
			# Check if "user_id" exists in the response
			if "user_id" in parsed_json:
				user_id = parsed_json["user_id"] # user is now logged in
				print("user_id: %d" % user_id)
				sign_up_worked = 1 # sign up did work
			else:
				print("user_id not found in response")
				sign_up_worked = -3 # there is no user
		else:
			print("Error parsing response JSON: %d" % error)
			sign_up_worked = -1 # the request sent an error
	elif response_code == 401: # bad username or password
		print("error, username or password incorrect")
		sign_up_worked = -4
	else: # the request failed
		print("Failed to send data. Response code: %d" % response_code)  # Log failure with response code
		sign_up_worked = -1
		
func upload_story(title: String, pages:Array, images:Array): # endpoint for uploading storys
	var url = BASE_URL + "add-story" # url for uploading stories
	# Prepare HTTPRequest
	var http_request = new_http("_on_upload_story_request_completed")
	# create data to be turned to multipost form data
	var form_data = {
		"user_id": user_id,
		"title": title,
		"pages": JSON.stringify(pages),
		"images": []
	}
	for image in images:
		var image_bytes = image
		form_data["images"].append(image_bytes) # add the image to the form data
	var boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW" # boundry for multipost form data
	var body = generate_multipart_data(form_data, boundary) # generate the body for the request as multipost
	var headers = [ # set the correct headers
		"Content-Type: multipart/form-data; boundary=" + boundary
	]
	http_request.request_raw(url, headers, HTTPClient.METHOD_POST, body) # send the reuqest
	
func _on_upload_story_request_completed(result, response_code, headers, body): # when upload story request completed
	if response_code == 200: # successfull error code
		print("Request Succeded")
		print(str(body))
	else: # error with request
		print("Request Failed with response code: ", response_code)
		
func generate_multipart_data(data, boundary): # creates the multipart form data for the stories uploading
	var line = "" # this is a placeholder for the current line to upload to the packedbytearray data
	var body = PackedByteArray() # body of request
	for key in data.keys(): # for each key in the data dictionary
		var value = data[key] # get the items relating to the key
		# For image data, we need to handle the file part specifically
		if key == "images":
			for item in value:
				var mime_type = get_extention(item) # get the image extention as png, jpeg, etc
				line = "--" + boundary + "\r\n" # open the image section of the form
				body.append_array(line.to_utf8_buffer())
				line = "Content-Disposition: form-data; name=\"" + key + "\"; filename=\"image." + mime_type + "\"\r\n"
				body.append_array(line.to_utf8_buffer())
				line = "Content-Type: image/" + mime_type + "\r\n\r\n"
				body.append_array(line.to_utf8_buffer())
				body.append_array(FileAccess.get_file_as_bytes(item)) # add the bytes of the image file
				line = "\r\n"
				body.append_array(line.to_utf8_buffer()) # close the image section of the form
		elif key == "image":
			var mime_type = get_extention(value) # get the image extention as png, jpeg, etc
			line = "--" + boundary + "\r\n" # open the image section of the form
			body.append_array(line.to_utf8_buffer())
			line = "Content-Disposition: form-data; name=\"" + key + "\"; filename=\"image." + mime_type + "\"\r\n"
			body.append_array(line.to_utf8_buffer())
			line = "Content-Type: image/" + mime_type + "\r\n\r\n"
			body.append_array(line.to_utf8_buffer())
			body.append_array(FileAccess.get_file_as_bytes(value)) # add the bytes of the image file
			line = "\r\n"
			body.append_array(line.to_utf8_buffer()) # close the image section of the form
		else: # add other data to the multipart form
			line = "--" + boundary + "\r\n"
			body.append_array(line.to_utf8_buffer())
			line = "Content-Disposition: form-data; name=\"" + key + "\"\r\n\r\n"
			body.append_array(line.to_utf8_buffer())
			line = str(value) + "\r\n" # convert the value to a string and add it
			body.append_array(line.to_utf8_buffer())
	line = "--" + boundary + "--\r\n" # close the body
	body.append_array(line.to_utf8_buffer())
	return body
	
func process_story(story_folder: String, user_id: int, title: String): # get story ready for uploading
	var pages # all pages to uplaod
	var page_names = [] # names of pages used to create the array of added pages
	var page_numbers = [] # number of each page used to create array of added pages
	var image_arr = [] # array of image to uplaod
	var story_dir = "res://Scenes/Levels/" # where all storys are located
	var story_path = story_dir + str(story_folder) + "/" # specific story location
	var dir = DirAccess.open(story_path) # open the story and check if it exists
	if dir.dir_exists:
		dir.list_dir_begin()
		var file_name = dir.get_next() # get the current file 
		while (file_name != ""): # if there is still files
			if dir.current_is_dir(): # if the item is a folder
				pass
			else: # if the item is not a folder it is a page
				page_names.append(file_name) # add the name of the page to page_names
			file_name = dir.get_next() # keep getting the next file to add all page_names
		sort_pages(page_names) # use custom sorting to sort the pages in order (page1, page2)
	else:
		print("An error occurred when trying to access the path.")
	page_numbers = get_page_numbers(page_names) # get the number of each page
	pages = create_pages_arr(page_names, page_numbers, story_path) # create the pages data to send
	image_arr = create_image_arr(page_names, story_path) # create the image array to send
	upload_story(title, pages, image_arr) # send the data and upload the story to the database
	
func get_page_numbers(page_names):
	var page_numbers = []
	for page in page_names: 
		var index = page.find(".tscn") # find the index of the text before the number
		if index != -1: 
			var number_string = page.substr(index - 1, index) # get the number through string splicing
			var number = number_string
			page_numbers.append(number) # add the number to page_numbers
		else:
			print("The expected format 'P.tscn' not found in the string.")
	return page_numbers # return all page numbers

func sort_pages(scenes_array: Array):
	var n = scenes_array.size() # amount of items in array
	var page_numbers = [] # holds the page number
	for item in scenes_array:
		var index_of_num = (item.find("P")) + 1 # find the pages number and the index of that number
		page_numbers.append(item[index_of_num])
	for end in range(n, 1, -1): # use this to create a "sorted" section of numbers
		var max_position = 0 # biggest number
		for i in range(1, end ): # go through all items in "unsorted" section
			if page_numbers[i] > page_numbers[max_position]: # used to find the largest number
				max_position = i
		# this logic below switches the largest number with the last number in the unsorted section, sorting the numbers
		var temp_num = page_numbers[end - 1]
		var temp_scene = scenes_array[end - 1]
		page_numbers[end -1 ] = page_numbers[max_position]
		scenes_array[end - 1] = scenes_array[max_position]
		page_numbers[max_position] = temp_num
		scenes_array[max_position] = temp_scene

func create_pages_arr(page_names: Array, page_numbers: Array, story_folder_path): # creates the array containing pages with text and images
	var pages = []
	for i in range(page_names.size()):
		var scene_name = page_names[i]
		var page_number = page_numbers[i]
		# Load the scene dynamically
		var scene = load_scene(story_folder_path + scene_name)
		if scene != null:
			# Get the text content from the scene's method
			var text_content = get_text_from_scene(scene)       
			if text_content != "":
				# Add the page as a dictionary to the pages array
				var page = {
					"page_number": page_number,
					"text_content": str(text_content)
					}
				pages.append(page)
	# Now you have the pages array populated
	print(pages)
	return pages
# Function to load a scene dynamically

func load_scene(scene_path: String) -> Node: # loads each page so you can check for text or images
	var scene = load(scene_path)
	if scene:
		return scene.instantiate()  # Instantiate the scene if it's loaded successfully
	else:
		print("Error loading scene: ", scene_path)
		return null
# Function to get the text from the scene (Assuming each scene has a method `get_text_content`)

func create_image_arr(page_names, story_folder_path): # creates an array of the images in each story
	var image_arr = []
	for i in range(page_names.size()):
		var scene_name = page_names[i]
		# Load the scene dynamically
		var scene = load_scene(story_folder_path + scene_name)
		if scene != null:
			# Get the text content from the scene's method
			var image_content = get_image_from_scene(scene)       
			if image_content != null:
				image_arr.append(image_content)
	# Now you have the pages array populated
	return image_arr
	
func get_image_from_scene(scene: Node): # gets the image from each  page
	if scene.has_method("get_image_content"):
		return scene.get_image_content()
	else:
		print("Scene doesnt have the get_image_content method.")
		return null
		
func get_text_from_scene(scene: Node) -> String: # gets the text on each page
	if scene.has_method("get_text_content"): # create methods here
		return scene.get_text_content()  # Call the method and return the text
	else:
		print("Scene doesn't have the get_text_content method!")
		return ""
		
func get_extention(string_to_get: String): # gets the extension of an image (png, jpeg)
	var extention = string_to_get.substr(string_to_get.find(".") + 1).to_lower()
	return extention
	
	
# TESTING STUFF
# Call this function to send the image and data
func send_page(user_id: int, page_name: String, text_content: String, image):
	# Create HTTPRequest instance
	var url = BASE_URL + "upload"
	http_request = new_http("_on_send_page_request_completed")
	# Prepare the body of the request
	var form_data = {
		"user_id" = user_id,
		"page_name" = page_name,
		"text_content" = text_content,
		"image" = image
	}
	var boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
	var body = generate_multipart_data(form_data, boundary)
	var headers = [
		"Content-Type: multipart/form-data; boundary=" + boundary
	]
	# Send the request to the Node.js API
	http_request.request_raw(url, headers, HTTPClient.METHOD_POST, body)
	
func _on_send_page_request_completed(result, response_code, headers, body): # when upload story request completed
	if response_code == 200: # successfull error code
		print("Request Succeded")
		print(str(body))
	else: # error with request
		print("Request Failed with response code: ", response_code)

func get_page_modifications(user_id:int, page_name:String):
	var url = BASE_URL + "get-save?user_id=" + str(user_id) + "&page_name=" +str(page_name)
	http_request = new_http("_on_get_page_modifications")
	var headers = ["Content-Type: application/json"]
	http_request.request(url, headers, HTTPClient.METHOD_GET)
	await http_request.request_completed
	return text_url_extention_from_save

func _on_get_page_modifications(result, response_code, headers, body):
	if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json:
				# Set text content and url
				var text = json["text_content"]
				text_url_extention_from_save["text"] = text
				var image_url = json["image_url"]
				text_url_extention_from_save["url"] = image_url
				var extention = json["ext"]
				text_url_extention_from_save["ext"] = extention
				text_url_extention_from_save["worked"] = true
	else:
		print("Error fetching data, response code:", response_code)
		text_url_extention_from_save["worked"] = false
		
		
func get_image(image_url, ext):
	text_url_extention_from_save["worked"] = true
	extention = ext
	http_request = new_http("_on_get_image_request_completed")
	var headers = []
	var err = http_request.request(image_url, headers ,HTTPClient.METHOD_GET)
	if err != OK:
		print("Error making request: ", err)
		text_url_extention_from_save["worked"] = false
	await http_request.request_completed
	return texture_from_get_image
	

func _on_get_image_request_completed(result, response_code, headers, body):
	if response_code == 200:
		text_url_extention_from_save["worked"] = true
		var image = Image.new()
		var error
		if extention == ".png":
			error = image.load_png_from_buffer(body)
		elif extention == ".jpeg" or extention == ".jpg":
			error = image.load_jpg_from_buffer(body)
		else:
			error = image.load_png_from_buffer(body)
		if error != OK:
			print(error);
			text_url_extention_from_save["worked"] = false
		else:
			texture_from_get_image = ImageTexture.create_from_image(image)
	else:
		print("Request failed: ", response_code)
		print("Headers: ", headers) # Print headers for debugging
		print("Body: ", body)       # Print body for debugging
		text_url_extention_from_save["worked"] = false
		
