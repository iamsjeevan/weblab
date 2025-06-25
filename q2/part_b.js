// File: server.js
const express = require('express');
const { MongoClient } = require('mongodb');

const app = express();
const PORT = 3000;
const MONGO_URL = 'mongodb://127.0.0.1:27017';
const DB_NAME = 'universityDB';

// --- BODY PARSER SETUP ---
app.use((req, res, next) => {
    if (req.method === 'GET') return next();
    let data = '';
    req.on('data', chunk => { data += chunk; });
    req.on('end', () => {
        if (!data) return next();
        const params = new URLSearchParams(data);
        req.body = {};
        for (const [key, value] of params.entries()) { req.body[key] = value; }
        next();
    });
});
// --- END OF BODY PARSER SETUP ---

app.use(express.static('public'));

let db;
MongoClient.connect(MONGO_URL).then(client => {
    db = client.db(DB_NAME);
    app.listen(PORT, () => console.log(`Server on port ${PORT}. Open http://localhost:3000`));
}).catch(error => console.error('DB connect failed', error));


// --- ROUTES ---

// NEW: API endpoint to fetch all students
app.get('/allstudents', async (req, res) => {
    try {
        const students = await db.collection('students').find({}).toArray();
        res.json(students);
    } catch (e) {
        res.status(500).json({ message: "Failed to fetch students" });
    }
});

app.post('/addstudent', async (req, res) => {
    try {
        const student = {
            Student_name: req.body.Student_name,
            USN: req.body.USN,
            Semester: parseInt(req.body.Semester),
            Exam_fee: req.body.Exam_fee ? parseInt(req.body.Exam_fee) : null
        };
        await db.collection('students').insertOne(student);
        res.redirect('/');
    } catch (e) {
        res.status(500).send('Failed to add student');
    }
});

app.post('/deletenonpayers', async (req, res) => {
    try {
        const query = { Exam_fee: { $in: [0, null] } };
        await db.collection('students').deleteMany(query);
        res.redirect('/');
    } catch (e) {
        res.status(500).send('Failed to delete students');
    }
});