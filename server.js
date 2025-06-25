const express = require('express');
const { MongoClient } = require('mongodb');
const path = require('path');
const app = express();
const uri = 'mongodb://127.0.0.1:27017';

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'complaint.html'));
});

app.post('/insert', async (req, res) => {
  const { user_name, issue } = req.body; 
  const client = await MongoClient.connect(uri);
  const collection = client.db('mydb').collection('complaints');
  
  await collection.insertOne({ user_name, issue, status: 'pending' });
  await client.close()
  res.send("insert successful")
})

app.post('/update', async (req, res) => {
  const { user_name, status } = req.body;  
  const client = await MongoClient.connect(uri);
  const collection = client.db('mydb').collection('complaints');
  
  const result = await collection.findOneAndUpdate({ user_name: user_name },{ $set: { status } },{ returnDocument: 'after' })
  await client.close()
  res.send(result)
})

app.get('/pending', async (req, res) => {  
  const client = await MongoClient.connect(uri);
  const collection = client.db('mydb').collection('complaints');
  
  const result = await collection.find({ status: 'pending' }).toArray()
  await client.close()
  res.send(result)
})

app.listen(3000)
