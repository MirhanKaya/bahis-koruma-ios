const express = require('express');
const router  = express.Router();

const GEO_POOL = [
  { city: 'İstanbul',  country: 'Türkiye', countryCode: 'TR', lat: 41.0082,  lng: 28.9784,  userCount: 312, recentIPs: ['88.229.1.1','88.229.1.2','88.229.1.3'] },
  { city: 'Ankara',    country: 'Türkiye', countryCode: 'TR', lat: 39.9334,  lng: 32.8597,  userCount: 147, recentIPs: ['78.180.2.1','78.180.2.2'] },
  { city: 'İzmir',     country: 'Türkiye', countryCode: 'TR', lat: 38.4192,  lng: 27.1287,  userCount:  98, recentIPs: ['176.88.3.1','176.88.3.2'] },
  { city: 'Antalya',   country: 'Türkiye', countryCode: 'TR', lat: 36.8969,  lng: 30.7133,  userCount:  74, recentIPs: ['85.105.4.1'] },
  { city: 'Bursa',     country: 'Türkiye', countryCode: 'TR', lat: 40.1885,  lng: 29.0610,  userCount:  61, recentIPs: ['88.228.5.1'] },
  { city: 'Adana',     country: 'Türkiye', countryCode: 'TR', lat: 37.0000,  lng: 35.3213,  userCount:  39, recentIPs: ['78.177.6.1'] },
  { city: 'Trabzon',   country: 'Türkiye', countryCode: 'TR', lat: 41.0027,  lng: 39.7168,  userCount:  22, recentIPs: ['78.161.7.1'] },
  { city: 'Berlin',    country: 'Almanya', countryCode: 'DE', lat: 52.5200,  lng: 13.4050,  userCount:  88, recentIPs: ['77.180.8.1','77.180.8.2'] },
  { city: 'London',    country: 'İngiltere', countryCode: 'GB', lat: 51.5074, lng: -0.1278,  userCount:  67, recentIPs: ['82.132.9.1'] },
  { city: 'New York',  country: 'ABD',     countryCode: 'US', lat: 40.7128,  lng: -74.0060, userCount:  43, recentIPs: ['173.252.10.1'] },
  { city: 'Amsterdam', country: 'Hollanda', countryCode: 'NL', lat: 52.3676, lng: 4.9041,   userCount:  31, recentIPs: ['213.127.11.1'] },
  { city: 'Dubai',     country: 'BAE',     countryCode: 'AE', lat: 25.2048,  lng: 55.2708,  userCount:  19, recentIPs: ['94.200.12.1'] },
];

function buildStats() {
  const byCountry = {};
  GEO_POOL.forEach(({ country, countryCode, userCount }) => {
    if (!byCountry[country]) byCountry[country] = { country, countryCode, userCount: 0 };
    byCountry[country].userCount += userCount;
  });

  const topCities   = [...GEO_POOL].sort((a, b) => b.userCount - a.userCount).slice(0, 5);
  const topCountries= Object.values(byCountry).sort((a, b) => b.userCount - a.userCount).slice(0, 3);
  const totalUsers  = GEO_POOL.reduce((s, x) => s + x.userCount, 0);

  return { topCities, topCountries, totalUsers };
}

router.get('/', (req, res) => {
  const stats = buildStats();
  res.json({
    success:     true,
    locations:   GEO_POOL,
    topCities:   stats.topCities,
    topCountries: stats.topCountries,
    totalUsers:  stats.totalUsers,
    generatedAt: new Date().toISOString()
  });
});

module.exports = router;
