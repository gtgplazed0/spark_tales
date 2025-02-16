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

// Endpoint to handle story modifications upload
app.post("/upload", upload.single("image"), async (req, res) => {
	try {
		const { user_id, page_name, text_content } = req.body;
		if (!user_id || !page_name || !text_content || !req.file) {
      console.log("Missing required fields")
			return res.status(400).json({ error: "Missing required fields" });
		}

		// Upload image to S3
		const fileName = `${Date.now()}_${req.file.originalname}`;
    console.log(req.file.originalname)
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

app.get('/get-save', async (req, res) => {
  try{
    const {user_id, page_name} = req.query;
    if (!user_id || !page_name) {
      return res.status(400).json({error: "Incorrect data. Needs user_id and page_name"})
    }
    const sql = "Select text_content, image_url FROM page_modifications WHERE user_id = ? AND page_name = ?";
    const [rows] = await db.execute(sql, [user_id, page_name]);
		if (rows.length === 0) {
			return res.status(404).json({ error: "Page not found" });
		}
    const image_url = rows[0].image_url
    const extension = path.extname(image_url)
    console.log(extension)
    // Extract S3 file key from URL
		const fileKey = image_url.split("/").pop();

		// Generate a signed URL (valid for 5 minutes)
		const signedUrl = s3.getSignedUrl("getObject", {
			Bucket: "spark-tales-s3-bucket",
			Key: fileKey,
			Expires: 300, // Link expires in 300 seconds (5 minutes)
		});
		res.status(200).json({ text_content: rows[0].text_content, image_url: signedUrl, ext: extension});
  } catch (err){
    console.error("Error:", err);
		res.status(500).json({ error: "Server error" });
  }
});



//testing sticker code




// Endpoint to handle story modifications upload
app.post("/upload-sticker", upload.single("image"), async (req, res) => {
	try {
		const { user_id} = req.body;
		if (!user_id || !req.file) {
      console.log("Missing required fields")
			return res.status(400).json({ error: "Missing required fields" });
		}

		// Upload image to S3
		const fileName = `${Date.now()}_${req.file.originalname}`;
    console.log(req.file.originalname)
		const params = {
			Bucket: "spark-tales-s3-bucket",
			Key: fileName,
			Body: req.file.buffer,
			ContentType: req.file.mimetype,
		};

		const uploadResult = await s3.upload(params).promise();
		const sticker_url = uploadResult.Location; // S3 File URL

		// Save details to the database
		const sql = `INSERT INTO stickers (user_id, sticker_url) VALUES (?, ?)`;
		await db.execute(sql, [user_id, sticker_url]);

		// Response
		res.status(200).json({ success: true }); // success status message
	} catch (err) {
		console.error("Error:", err);
		res.status(500).json({ error: "Server error" });
	}
});

app.get('/get-stickers', async (req, res) => {
  try{
    const {user_id} = req.query;
    if (!user_id) {
      return res.status(400).json({error: "Incorrect data. Needs user_id"})
    }
    const sql = "Select sticker_url FROM stickers WHERE user_id = ?";
    const [rows] = await db.execute(sql, [user_id]);
		if (rows.length === 0) {
			return res.status(404).json({ error: "stickers not found" });
		}
   // Create an array of sticker URLs with signed URLs
    const stickers = rows.map(row => {
      const image_url = row.sticker_url;
      const extension = path.extname(image_url);
      
      // Extract S3 file key from URL
      const fileKey = image_url.split("/").pop();

      // Generate a signed URL (valid for 5 minutes)
      const signedUrl = s3.getSignedUrl("getObject", {
        Bucket: "spark-tales-s3-bucket",
        Key: fileKey,
        Expires: 300, // Link expires in 300 seconds (5 minutes)
      });

      return {
        image_url: signedUrl,
        ext: extension,
      };
    });
  // Send the array of stickers
  res.status(200).json({ stickers });

  } catch (err){
    console.error("Error:", err);
		res.status(500).json({ error: "Server error" });
  }
});
module.exports = app;