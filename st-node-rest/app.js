const express = require('express');

const bcrypt = require('bcryptjs');  // To hash and compare passwords

const bodyParser = require('body-parser'); // To parse JSON request bodies

const app = express();

const crypto = require('crypto');

const multer = require('multer');

const cors=require('cors');

const AWS = require("aws-sdk");

const multerS3 = require("multer-s3");

const fs = require('fs');

const path = require('path');

const mysql = require("mysql2/promise");
const { stringify } = require('querystring');

const storage = multer.memoryStorage();  // Use memoryStorage to handle raw binary data in Buffer form


// Configure AWS S3
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: "us-east-2",
});


const db = mysql.createPool({ //creating conenction to database using the mysql library and the credentials to my MySQL database
  //using environment variables that connect to my railway hosting platform to hide and encrypt sensitive data
  // using || when specifying port numbers to ensure error checking
  host: process.env.DB_HOST,
  user: process.env.DB_USER, 
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  port: process.env.PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
  
});

const upload = multer({ storage: multer.memoryStorage() });

app.use(express.urlencoded({ extended: true }));
console.log(process.env.DB_HOST)
console.log(process.env.DB_NAME)
console.log(process.env.DB_USER)
console.log(process.env.DB_PASS)
// Middleware to parse JSON
app.use(express.json());
app.use(cors())
app.options('*', cors());
app.get('/', (req, res) => {
    res.status(200).json({
        message: "Welcome to the API!"
    });
    
});

function testCORS(req, res) {
  res.send('CORS test successful!');
}

// Create a test route for CORS
app.get('/test-cors', testCORS); 

// Route to check all tables in the database
app.get('/check-tables', async (req, res) => {
  try {
      // Query to retrieve table names from the information schema
      const query = `SELECT table_name 
                     FROM information_schema.tables 
                     WHERE table_schema = '${process.env.DB_NAME}'`;
      const [results] = await db.query(query);

      // Map results to an array of table names
      const tableNames = results.map(row => row.TABLE_NAME);

      res.status(200).json({
          message: "Tables retrieved successfully!",
          tables: tableNames,
      });
      console.log("Tables retrieved:", tableNames);
  } catch (err) {
      console.error('Error fetching tables:', err);
      res.status(500).json({ result: 'error', message: 'Internal server error' });
  }
});

app.post('/users', async (req, res) => { //setup an asynchronous HTTPS POST request to /users
    const { username, salt, hashed_password } = req.body; //deconstruct request.body to for the username, salt, and hashed_password fields
    try {
        // Insert data into a table called `users`
        const [result] = await db.query('INSERT INTO users (username, salt, hashed_password) VALUES (?, ?, ?)', [username, salt, hashed_password]);
        
        res.status(201).json({ //send a success response code with success message
            message: "Data saved to the database!",
            insertedId: result.insertId, //id of user
        });
        console.log("inserted");
    } catch (err) { //catch errors and send duplicate entry status or insertion error status
        if (err.code == 'ER_DUP_ENTRY') { 
            // Handle duplicate username error
            return res.status(409).json({ result: 'error', message: 'Username already exists' });
        } else {
            console.error('Error inserting user:', err);
            return res.status(500).json({ result: 'error', message: 'Internal server error' });
        }
    }
});

app.get('/users', async (req, res) => { // use a asynchronous HTTP GET request to get a list of all users (testing)
    try {
        // Retrieve all rows from `data_table`
        const [rows] = await db.query('SELECT * FROM users'); 
        
        res.status(200).json({ // send the success status
            message: "Data retrieved successfully!",
            data: rows,
        }
      );
    } catch (err) { //error catching
        console.log("failed to retrive data")
        res.status(500).json({ //send error status
            message: "Failed to retrieve data",
            error: err.message
        });
    }
});

app.post('/login', async (req, res) => { //asynchronous HTTPS POST request to sign in the user via username and password
  const { username, password } = req.body; //get username and password from the request body

  try {
    // aysnc with query function to get the user id, username, salt, and hashed_password from the correct user
    const [results] = await db.query('SELECT user_id, username, salt, hashed_password FROM users WHERE username = ?', [username]); 

    if (results.length === 0) {
      return res.status(401).json({ result: 'error', message: 'Invalid username or password' }); // error result if there is no result (wrong user or pass)
    }

    const user = results[0]; //user_id

    const combined = password + user.salt; // combine pass with salt to hash 
    const hashedEnteredPassword = crypto.createHash('sha256').update(combined).digest('hex'); // use sha256 (same hashing in godot) to has the password

    if (hashedEnteredPassword === user.hashed_password) { // check if the passwords were the same
      return res.status(200).json({ result: 'success', message: 'Login successful', user_id: user.user_id });  // success message
    } else {
      return res.status(401).json({ result: 'error', message: 'Invalid username or password' }); //error message if the passwords are wrong
    }
  } catch (err) { //catch errors 
    console.log("database error on login", err); 
    return res.status(500).json({ result: 'error', message: 'Database error' });  // return error status message
  }
});

// Endpoint to handle image upload
app.post("/upload", upload.single("image"), async (req, res) => {
	try {
		const { user_id, page_name, text_content } = req.body;
		if (!user_id) {
      console.log("Missing required fields: User_id")
			return res.status(400).json({ error: "Missing required fields" });
		}
    if (!page_name) {
      console.log("Missing required fields: Page_name")
			return res.status(400).json({ error: "Missing required fields" });
		}
    if (!text_content) {
      console.log("Missing required fields: Text_content")
			return res.status(400).json({ error: "Missing required fields" });
		}
    if (!req.file) {
      prconsole.logint("Missing required fields: image files")
			return res.status(400).json({ error: "Missing required fields" });
		}

		// Upload image to S3
		const fileName = `${Date.now()}_${req.file.originalname}`;
		const params = {
			Bucket: "spark-tales-s3-bucket",
			Key: fileName,
			Body: req.file.buffer,
			ContentType: req.file.mimetype,
		};

		const uploadResult = await s3.upload(params).promise();
		const imageUrl = uploadResult.Location; // S3 File URL

		// Save details to the database
		const sql = `
			INSERT INTO page_modifications (user_id, page_name, text_content, image_url) 
			VALUES (?, ?, ?, ?) 
			ON DUPLICATE KEY UPDATE 
				text_content = VALUES(text_content), 
				image_url = VALUES(image_url);
		`;
		await db.execute(sql, [user_id, page_name, text_content, imageUrl]);

		// Response
		res.status(200).json({ success: true }); // success status message
	} catch (err) {
		console.error("Error:", err);
		res.status(500).json({ error: "Server error" });
	}
});

app.post('/add-story', upload.array('images', 10), async (req, res) => { // asynchronous HTTPS POST request to upload an array of images (in multiform data) and the story to a database and s3 file system
  const { user_id, title } = req.body; //get the user_id and title of the story from request body
  if (!user_id || !title) {
    return res.status(400).send('User ID and Story Title are required'); //errror status message
  }
  try {
    const [storyResult] = await db.query(
      'INSERT INTO stories (title, user_id) VALUES (?, ?)', //insert the user_id and the title into the database. Titles are unique to each user_id
      [title, user_id]
    );
    const story_id = storyResult.insertId; //get the id of the new story
    //add pages
    const pages = JSON.parse(req.body.pages); // Pages info is sent as JSON string. parse the string 
    for (let i = 0; i < pages.length; i++) {  //for loop to add all pages and image urls to the database in reference to their story_id
      let imageUrl = null
      const { page_number, text_content } = pages[i]; // get the page number and text on the page
      // Check if there is a corresponding image file for this page
      if (req.files && req.files[i]) {
        const file = req.files[i]; // Get the file for the current page (if available)
        imageUrl = file.location; //make the image url the file location
      }
      // Insert the page into the database
      const [pageResult] = await db.query(
        'INSERT INTO pages (story_id, page_number) VALUES (?, ?)',
        [story_id, page_number]
      );
      const page_id = pageResult.insertId;

      // Insert page content into the database, including the image URL if available
      await db.query(
        'INSERT INTO page_content (user_id, page_id, text_content, image_url) VALUES (?, ?, ?, ?)',
        [user_id, page_id, text_content, imageUrl]
      );
    }
      res.status(200).json({ success: true }); // success status message
      console.log("inserted story into database! StoryID: ", story_id)
    } catch (error) {
      console.error('Error processing upload:', error); 
      res.status(500).json({ error: 'Failed to process upload.' });// failure status message.
    }
 });
 


app.delete('/delete-story/:story_id', async (req, res) => { // use a HTTPS DELETE request to delete a story. Database uses cascade to delete pages and content
    const { story_id } = req.params;
  
    if (!story_id) {
      return res.status(400).send('Story ID is required'); // error status message if no id is provided
      console.log("story ID is required")
    }
  
    try {
      // Delete the story (cascade will handle pages and content)
      const [result] = await db.query(
        'DELETE FROM stories WHERE story_id = ?', //delete the story
        [story_id]
      );
  
      if (result.affectedRows === 0) {
        return res.status(404).send('Story not found'); // story not found error message
        console.log("story not found")
      } 
  
      res.status(200).send('Story and associated data deleted successfully'); // success status message
      console.log("story and data deleted")
    } catch (error) {
      console.error(error);
      res.status(500).send('Error deleting story'); //error status message
      console.log("error deleting story")
    }
  }); 
  
module.exports = app;