// File: server.js
const express = require('express');
const { MongoClient } = require('mongodb');

const app = express();
const PORT = 3000;
const MONGO_URL = 'mongodb://127.0.0.1:27017';
const DB_NAME = 'complaintDB';

// --- BODY PARSER SETUP (CHOOSE ONE METHOD) ---

// METHOD 1: The standard, built-in way. Try this first.
// If it works, delete the manual parser.
// app.use(express.urlencoded({ extended: true })); // For HTML forms
// app.use(express.json()); // For API calls (from our JS)


// METHOD 2: The manual, guaranteed way. (ACTIVE BY DEFAULT)
app.use((req, res, next) => {
    if (req.method === 'GET') return next();
    let data = '';
    req.on('data', chunk => { data += chunk; });
    req.on('end', () => {
        if (!data) return next();
        const contentType = req.headers['content-type'] || '';
        try {
            if (contentType.includes('application/x-www-form-urlencoded')) {
                const params = new URLSearchParams(data);
                req.body = {};
                for (const [key, value] of params.entries()) { req.body[key] = value; }
            } else if (contentType.includes('application/json')) {
                req.body = JSON.parse(data);
            }
        } catch (e) { console.log('Parsing error'); }
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

app.post('/complaints', async (req, res) => {
    try {
        await db.collection('complaints').insertOne(req.body);
        res.redirect('/');
    } catch (e) { res.status(500).send('Failed to create'); }
});

app.put('/complaints/:id', async (req, res) => {
    try {
        const result = await db.collection('complaints').updateOne(
            { ComplaintID: req.params.id },
            { $set: { Status: req.body.Status } }
        );
        if (result.matchedCount === 0) return res.status(404).send({ message: 'Not found' });
        res.send({ message: 'Updated' });
    } catch (e) { res.status(500).send('Failed to update'); }
});

app.get('/pending', async (req, res) => {
    try {
        const complaints = await db.collection('complaints').find({ Status: { $ne: 'Resolved' } }).toArray();
        res.json(complaints);
    } catch (e) { res.status(500).send('Failed to fetch'); }
});