const fs = require('fs');
const path = require('path');

const FILE_PATH = path.join(__dirname, '../data/domains.json');

function readDomains() {
  try {
    const raw = fs.readFileSync(FILE_PATH, 'utf-8');
    return JSON.parse(raw);
  } catch {
    return [];
  }
}

function writeDomains(domains) {
  fs.writeFileSync(FILE_PATH, JSON.stringify(domains, null, 2), 'utf-8');
}

function nextId(domains) {
  if (domains.length === 0) return 1;
  return Math.max(...domains.map(d => d.id)) + 1;
}

module.exports = { readDomains, writeDomains, nextId };
