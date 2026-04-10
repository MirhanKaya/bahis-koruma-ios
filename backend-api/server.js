const app = require('./app');

const PORT = process.env.PORT || 8000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[backend] Bahis Koruma API running on port ${PORT}`);
  console.log(`[backend] Endpoints:`);
  console.log(`[backend]   GET    /health`);
  console.log(`[backend]   GET    /domains`);
  console.log(`[backend]   POST   /domains`);
  console.log(`[backend]   DELETE /domains/:id`);
  console.log(`[backend]   POST   /classify-domain`);
});
