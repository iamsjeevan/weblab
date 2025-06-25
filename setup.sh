#!/bin/bash

# Create project directory
mkdir -p q2/public

# package.json for part (b)
cat > q2/package.json <<'EOF'
{
  "name": "q2-app",
  "version": "1.0.0",
  "description": "Question 2 Solution",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.17.1",
    "mongodb": "^3.6.3"
  }
}
EOF

# Part (a) Solution
echo "Part (a): JavaScript program to convert month number to month name using closures."
echo "The HTML file 'part_a.html' contains a script demonstrating this."
echo "Input a number, and it will display the month name or 'Bad Number' based on validation rules."
echo "Decimal inputs between 1 and 12 will have their decimal part stripped."

cat > q2/part_a.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Q2 Part A: Month Converter</title>
</head>
<body>
    <h1>Month Number to Name Converter</h1>
    <label for="monthNumberInput">Enter month number (1-12):</label>
    <input type="text" id="monthNumberInput" placeholder="e.g., 3 or 7.5">
    <button onclick="convertMonth()">Convert</button>
    <p>Month Name: <span id="monthNameField"></span></p>

    <script>
        function createMonthConverter() {
            const monthNames = [
                "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"
            ];

            return function(monthNumberStr) {
                const num = parseFloat(monthNumberStr);

                if (isNaN(num)) {
                    return "Bad Number";
                }

                if (num < 1 || num > 12) {
                     // Check if it's a decimal that would truncate to a valid month
                    const truncatedNum = Math.trunc(num);
                    if (truncatedNum >= 1 && truncatedNum <= 12) {
                         return monthNames[truncatedNum - 1];
                    }
                    return "Bad Number";
                }
                
                const index = Math.trunc(num); // Strip decimal part
                if (index >= 1 && index <= 12) {
                    return monthNames[index - 1];
                }
                
                return "Bad Number"; // Should not be reached if logic is correct
            };
        }

        const getMonthName = createMonthConverter();

        function convertMonth() {
            const inputElement = document.getElementById('monthNumberInput');
            const outputElement = document.getElementById('monthNameField');
            const monthName = getMonthName(inputElement.value);
            outputElement.textContent = monthName;
        }
    </script>
</body>
</html>
EOF

# Part (b) Solution
echo ""
echo "Part (b): Node.js application for student details."
echo "The 'server.js' file sets up a Node.js/Express server with MongoDB."
echo "It handles:"
echo " - Accepting student details (Student_name, USN, Semester, Exam_fee) via a web form."
echo " - Storing submitted data in a MongoDB collection."
echo " - Deleting all students who have not paid the exam fee (Exam_fee = 0 or null)."
echo "The 'public/index.html' file provides a UI for these operations."

cat > q2/server.js <<'EOF'
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
EOF

cat > q2/public/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Q2 Part B: Student Details Management</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: auto; }
        form, .section { margin-bottom: 20px; padding: 15px; border: 1px solid #ccc; border-radius: 5px; }
        label { display: block; margin-bottom: 5px; }
        input[type="text"], input[type="number"] { width: calc(100% - 12px); padding: 8px; margin-bottom: 10px; border: 1px solid #ddd; border-radius: 3px; }
        button { padding: 10px 15px; background-color: #28a745; color: white; border: none; border-radius: 3px; cursor: pointer; margin-right: 5px; }
        button:hover { background-color: #1e7e34; }
        button.delete { background-color: #dc3545; }
        button.delete:hover { background-color: #c82333; }
        ul { list-style-type: none; padding: 0; }
        li { padding: 10px; border-bottom: 1px solid #eee; }
        li:last-child { border-bottom: none; }
        .student-item span { margin-right: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Student Details Management</h1>

        <form id="addStudentForm">
            <h2>Add New Student</h2>
            <label for="student_name">Student Name:</label>
            <input type="text" id="student_name" name="student_name" required>
            <label for="usn">USN:</label>
            <input type="text" id="usn" name="usn" required>
            <label for="semester">Semester:</label>
            <input type="number" id="semester" name="semester" required>
            <label for="exam_fee">Exam Fee (leave empty or 0 if not paid):</label>
            <input type="number" id="exam_fee" name="exam_fee" step="any" placeholder="e.g., 1500 or 0">
            <button type="submit">Add Student</button>
        </form>

        <div class="section">
            <h2>Actions</h2>
            <button class="delete" onclick="deleteUnpaidStudents()">Delete Students with Unpaid Exam Fee</button>
        </div>

        <div class="section">
            <h2>Student List</h2>
            <button onclick="fetchStudents()">Refresh List</button>
            <ul id="studentsList"></ul>
        </div>
    </div>

    <script>
        const addStudentForm = document.getElementById('addStudentForm');
        const studentsList = document.getElementById('studentsList');

        addStudentForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(addStudentForm);
            const studentData = {};
            // FormData does not distinguish well between empty string and 0 for numbers if type="number"
            // So we handle exam_fee explicitly.
            formData.forEach((value, key) => {
                studentData[key] = value;
            });
             if (studentData.exam_fee === '') { // If empty, server will treat as null
                studentData.exam_fee = ''; // Send as empty string
            } else {
                studentData.exam_fee = parseFloat(studentData.exam_fee);
            }


            try {
                const response = await fetch('/students', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(studentData)
                });
                if (!response.ok) throw new Error('Failed to add student: ' + await response.text());
                addStudentForm.reset();
                fetchStudents(); // Refresh list
            } catch (error) {
                console.error(error);
                alert(error.message);
            }
        });

        async function deleteUnpaidStudents() {
            if (!confirm('Are you sure you want to delete all students with unpaid (0 or null) exam fees?')) {
                return;
            }
            try {
                const response = await fetch('/students/unpaid', { method: 'DELETE' });
                if (!response.ok) throw new Error('Failed to delete unpaid students: ' + await response.text());
                const result = await response.json();
                alert(result.message);
                fetchStudents(); // Refresh list
            } catch (error) {
                console.error(error);
                alert(error.message);
            }
        }
        
        async function fetchStudents() {
            try {
                const response = await fetch('/students');
                if (!response.ok) throw new Error('Failed to fetch students: ' + await response.text());
                const students = await response.json();
                
                studentsList.innerHTML = '';
                if (students.length === 0) {
                    studentsList.innerHTML = '<li>No students found.</li>';
                    return;
                }
                students.forEach(s => {
                    const li = document.createElement('li');
                    li.className = 'student-item';
                    li.innerHTML = `
                        <span><strong>Name:</strong> ${s.student_name}</span>
                        <span><strong>USN:</strong> ${s.usn}</span>
                        <span><strong>Semester:</strong> ${s.semester}</span>
                        <span><strong>Exam Fee:</strong> ${s.exam_fee === null ? 'N/A' : s.exam_fee}</span>
                        <span><em>(MongoID: ${s._id})</em></span>
                    `;
                    studentsList.appendChild(li);
                });
            } catch (error) {
                console.error(error);
                studentsList.innerHTML = `<li>Error loading students: ${error.message}</li>`;
            }
        }

        // Initial fetch
        fetchStudents();
    </script>
</body>
</html>
EOF

echo "Setup for Q2 complete. Navigate to q2 directory, run 'npm install' then 'npm start'."
echo "Open part_a.html in a browser for Part A."
echo "Open http://localhost:3000 in a browser for Part B."
