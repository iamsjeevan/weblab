// install the node_modules + node_mongo_2025 folder from server
// gedit server.js
// gedit employee.html
// node server.js
// Open browser and go to http://localhost:3000

// for mongodb>>

// sudo systemctl start mongod
// sudo systemctl enable mongod
// mongosh
// use HR
// db.createCollection('employees')

// no need to insert data manually, it will be done through the form

//-------------------------------------------------------------
// server.js
const express = require('express');
const { MongoClient } = require('mongodb');
const path = require('path');
const app = express();
const uri = 'mongodb://127.0.0.1:27017';

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'employee.html'));
});

app.get('/add-employee', async (req, res) => {
  const { emp_name, email, phone, hire_date, job_title, salary } = req.query;
  const parsedSalary = parseFloat(salary);

  const client = await MongoClient.connect(uri);
  const db = client.db('HR');
  const employees = db.collection('employees');
  await employees.insertOne({emp_name, email, phone, hire_date, job_title,salary: parsedSalary});
  const result = await employees.find({ salary: { $gt: 50000 } }).toArray();

  res.send(result);
  await client.close();
});

app.listen(3000);