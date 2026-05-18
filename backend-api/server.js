const app = require('./app');
const { seedFirestoreFromLocalIfEmpty, isAvailable } = require('./utils/firebase');
const { readDomains } = require('./utils/storage');

const PORT = process.env.PORT || 8000;

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`[backend] Bahis Koruma API running on port ${PORT}`);
  console.log(`[backend] Endpoints:`);
  console.log(`[backend]   GET    /health`);
  console.log(`[backend]   GET    /domains`);
  console.log(`[backend]   POST   /domains`);
  console.log(`[backend]   DELETE /domains/:id`);
  console.log(`[backend]   POST   /classify-domain`);

  // One-time seed: if Firestore is connected and the `domains` collection is
  // empty, populate it from local JSON so mobile clients have data immediately
  // without a manual first write through the admin panel.
  if (isAvailable()) {
    const local = readDomains();
    await seedFirestoreFromLocalIfEmpty(local);
  }
});
