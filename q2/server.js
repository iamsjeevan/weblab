const express = require('express');
const { MongoClient } = require('mongodb');

const app = express();
const port = 3000;

const mongoUrl = 'mongodb://localhost:27017';
const dbName = 'webtech_lab_q2';
let db;

MongoClient.connect(mongoUrl, { useNewUrlParser: true, useUnifiedTopology: true }, (err, client) => {
    if (err) {
        console.error('Failed to connect to MongoDB:', err);
        process.exit(1);
    }
    console.log('Connected to MongoDB');
    db = client.db(dbName);
});

function manualBodyParser(req, res, next) {
    if ((req.method === 'POST' || req.method === 'PUT' || req.method === 'DELETE') && req.headers['content-type']) {
        let rawData = '';
        req.on('data', chunk => {
            rawData += chunk;
        });
        req.on('end', () => {
            try {
                if (req.headers['content-type'].includes('application/json')) {
                    req.body = rawData ? JSON.parse(rawData) : {};
                } else if (req.headers['content-type'].includes('application/x-www-form-urlencoded')) {
                    const params = new URLSearchParams(rawData);
                    req.body = {};
                    for (const [key, value] of params) {
                        req.body[key] = value;
                    }
                } else {
                    req.body = {};
                }
            } catch (error) {
                console.error('Error parsing body:', error);
                req.body = {};
            }
            next();
        });
         req.on('error', (err) => {
            console.error('Request error:', err);
            next(err);
        });
    } else {
        next();
    }
}

app.use(manualBodyParser);
app.use(express.static('public'));

app.post('/students', async (req, res) => {
    try {
        let { student_name, usn, semester, exam_fee } = req.body;
        if (!student_name || !usn || !semester) { // exam_fee can be 0 or null
            return res.status(400).json({ message: 'Student Name, USN, and Semester are required.' });
        }
        
        // Convert exam_fee to number, handle empty string as null
        exam_fee = exam_fee === '' ? null : parseFloat(exam_fee);
        if (exam_fee !== null && isNaN(exam_fee)) {
             return res.status(400).json({ message: 'Exam fee must be a number or empty.' });
        }


        const newStudent = { student_name, usn, semester: parseInt(semester), exam_fee, submittedAt: new Date() };
        const result = await db.collection('students').insertOne(newStudent);
        res.status(201).json(result.ops[0]);
    } catch (error) {
        console.error('Error adding student:', error);
        res.status(500).json({ message: 'Failed to add student.' });
    }
});

app.get('/students', async (req, res) => {
    try {
        const students = await db.collection('students').find({}).toArray();
        res.status(200).json(students);
    } catch (error) {
        console.error('Error fetching students:', error);
        res.status(500).json({ message: 'Failed to fetch students.' });
    }
});

app.delete('/students/unpaid', async (req, res) => {
    try {
        // Exam_fee = 0 or null
        const query = { $or: [{ exam_fee: 0 }, { exam_fee: null }] };
        const result = await db.collection('students').deleteMany(query);
        res.status(200).json({ message: `${result.deletedCount} students who did not pay the exam fee were deleted.` });
    } catch (error) {
        console.error('Error deleting unpaid students:', error);
        res.status(500).json({ message: 'Failed to delete unpaid students.' });
    }
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
