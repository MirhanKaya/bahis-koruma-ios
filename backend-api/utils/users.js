const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const FILE_PATH = path.join(__dirname, '../data/users.json');

const PLAN_DURATIONS = {
  trial:  7,
  pro_6:  180,
  pro_12: 365
};

function readUsers() {
  try {
    return JSON.parse(fs.readFileSync(FILE_PATH, 'utf-8'));
  } catch {
    return [];
  }
}

function writeUsers(users) {
  fs.writeFileSync(FILE_PATH, JSON.stringify(users, null, 2), 'utf-8');
}

function generateApiKey() {
  return crypto.randomBytes(24).toString('hex');
}

function expiresAtForPlan(plan) {
  const days = PLAN_DURATIONS[plan] ?? PLAN_DURATIONS.trial;
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString();
}

function findByEmail(email) {
  return readUsers().find(u => u.email === email.toLowerCase()) || null;
}

function findByApiKey(apiKey) {
  return readUsers().find(u => u.apiKey === apiKey) || null;
}

function createUser(email) {
  const users = readUsers();
  const newUser = {
    id: crypto.randomUUID(),
    email: email.toLowerCase(),
    apiKey: generateApiKey(),
    plan: 'trial',
    expiresAt: expiresAtForPlan('trial'),
    createdAt: new Date().toISOString()
  };
  users.push(newUser);
  writeUsers(users);
  return newUser;
}

function updateUserPlan(email, plan) {
  if (!PLAN_DURATIONS[plan]) return null;
  const users = readUsers();
  const user = users.find(u => u.email === email.toLowerCase());
  if (!user) return null;
  user.plan = plan;
  user.expiresAt = expiresAtForPlan(plan);
  writeUsers(users);
  return user;
}

function isExpired(user) {
  return new Date(user.expiresAt) < new Date();
}

module.exports = {
  readUsers,
  findByEmail,
  findByApiKey,
  createUser,
  updateUserPlan,
  isExpired,
  PLAN_DURATIONS
};
