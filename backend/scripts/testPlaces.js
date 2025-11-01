/*
  Simple CLI to test nearby healthcare search using Geoapify (preferred),
  Google Places, or OSM/Nominatim.

  Usage examples:
    node scripts/testPlaces.js --lat 12.9716 --lon 77.5946 --radius 5000 --keywords "hospital clinic doctor"
    node scripts/testPlaces.js --provider geoapify --lat 19.0760 --lon 72.8777

  Provider selection order (if --provider not passed): GEOAPIFY > GOOGLE > OSM
  - Set GEOAPIFY_API_KEY or GOOGLE_PLACES_API_KEY via env or .env
*/

require('dotenv').config();
const axios = require('axios');

function parseArgs(argv) {
  const out = { radius: 3000, keywords: 'hospital clinic doctor' };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    const next = argv[i + 1];
    if (a === '--lat') out.lat = parseFloat(next), i++;
    else if (a === '--lon') out.lon = parseFloat(next), i++;
    else if (a === '--radius') out.radius = parseInt(next, 10), i++;
    else if (a === '--keywords') out.keywords = next, i++;
    else if (a === '--provider') out.provider = (next || '').toLowerCase(), i++;
  }
  return out;
}

function toRad(deg) { return (deg * Math.PI) / 180; }
function distanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

async function run() {
  const { lat, lon, radius, keywords, provider } = parseArgs(process.argv);
  if (!lat || !lon) {
    console.error('Missing --lat and --lon');
    process.exit(1);
  }

  const geoapifyKey = process.env.GEOAPIFY_API_KEY;
  const googleKey = process.env.GOOGLE_PLACES_API_KEY;

  let chosen = provider;
  if (!chosen) chosen = geoapifyKey ? 'geoapify' : (googleKey ? 'google' : 'osm');

  console.log(`[testPlaces] Provider=${chosen} lat=${lat} lon=${lon} radius=${radius} keywords=${keywords}`);

  try {
    if (chosen === 'geoapify') {
      const cats = [];
      const kw = keywords.toLowerCase();
      if (kw.includes('hospital')) cats.push('healthcare.hospital');
      if (kw.includes('clinic')) cats.push('healthcare.clinic_or_praxis');
      if (kw.includes('doctor')) cats.push('healthcare.clinic_or_praxis');
      if (cats.length === 0) cats.push('healthcare.clinic_or_praxis');

      const url = 'https://api.geoapify.com/v2/places';
      const params = {
        categories: cats.join(','),
        filter: `circle:${lon},${lat},${radius}`,
        bias: `proximity:${lon},${lat}`,
        limit: 10,
        apiKey: geoapifyKey,
      };
      const res = await axios.get(url, { params });
      const features = res.data?.features || [];
      const rows = features.map((f) => {
        const p = f.properties || {};
        const coords = (f.geometry && f.geometry.coordinates) || [0, 0];
        const d = distanceMeters(lat, lon, coords[1], coords[0]);
        return {
          name: p.name || 'Clinic',
          category: (p.categories && p.categories[0]) || p.category || 'clinic',
          address: p.formatted || p.address_line2 || '',
          distance_m: Math.round(d),
          place_id: p.place_id,
        };
      });
      console.table(rows.slice(0, 10));
      console.log(`[geoapify] Count=${rows.length}`);
      return;
    }

    if (chosen === 'google') {
      const url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
      const params = {
        location: `${lat},${lon}`,
        radius,
        keyword: keywords,
        key: googleKey,
      };
      const res = await axios.get(url, { params });
      const results = res.data?.results || [];
      const rows = results.map((r) => {
        const loc = r.geometry?.location || { lat: 0, lng: 0 };
        const d = distanceMeters(lat, lon, loc.lat, loc.lng);
        return {
          name: r.name,
          rating: r.rating,
          open_now: r.opening_hours?.open_now ?? null,
          vicinity: r.vicinity,
          distance_m: Math.round(d),
          place_id: r.place_id,
        };
      });
      console.table(rows.slice(0, 10));
      console.log(`[google] Status=${res.data?.status} Count=${rows.length}`);
      return;
    }

    // OSM/Nominatim fallback with bounded viewbox
    const deltaLat = radius / 1000 / 111.0;
    const rad = (lat * Math.PI) / 180.0;
    const cosLat = Math.abs(Math.cos(rad)) < 0.017 ? 0.017 : Math.cos(rad);
    const deltaLon = radius / 1000 / (111.0 * cosLat);
    const latMin = (lat - deltaLat).toFixed(6);
    const latMax = (lat + deltaLat).toFixed(6);
    const lonMin = (lon - deltaLon).toFixed(6);
    const lonMax = (lon + deltaLon).toFixed(6);
    const viewbox = `${lonMin},${latMin},${lonMax},${latMax}`;

    const url = 'https://nominatim.openstreetmap.org/search';
    const params = {
      format: 'jsonv2',
      q: keywords,
      lat: lat.toString(),
      lon: lon.toString(),
      addressdetails: '1',
      extratags: '1',
      namedetails: '1',
      bounded: '1',
      viewbox,
      limit: '10',
    };
    const res = await axios.get(url, {
      params,
      headers: {
        'User-Agent': 'CareVibeDemo/1.0 (contact: support@carevibe.example)',
        'Accept-Language': 'en',
      },
    });
    const list = res.data || [];
    const rows = list.map((e) => {
      const plat = parseFloat(e.lat || '0');
      const plon = parseFloat(e.lon || '0');
      const d = distanceMeters(lat, lon, plat, plon);
      return {
        name: (e.name || e.display_name || '').toString().split(',')[0],
        type: `${e.class || ''} ${e.type || ''}`.trim(),
        address: e.display_name,
        distance_m: Math.round(d),
      };
    });
    console.table(rows.slice(0, 10));
    console.log(`[osm] Count=${rows.length}`);
  } catch (err) {
    const status = err.response?.status;
    const data = err.response?.data;
    console.error('[testPlaces] Error', status || '', data?.status || data?.error || err.message);
    process.exit(2);
  }
}

run();


