const express = require('express');
const path = require('path');

const app = express();
const PORT = 5000;
const API_URL = 'http://localhost:8000';

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Admin panel running on http://0.0.0.0:${PORT}`);
});
