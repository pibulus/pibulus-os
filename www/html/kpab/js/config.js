const STATION = {
  name: 'KPAB.FM',                         // Station display name
  tagline: 'Pirate Radio',                 // Shown when no track metadata available
  subtitle: 'Broadcasting from Brunswick', // Header subtitle
  url: 'https://kpab.fm/',                 // Public URL (used by share feature)
  streamUrl: '/radio.mp3',                 // AzuraCast mount point for MP3 stream
  apiUrl: '/api/nowplaying/kpab.fm',       // AzuraCast now-playing API endpoint
  catalogUrl: '/catalog.json',             // Song catalog JSON (see README for schema)
  mutinyEndpoint: '/mutiny/mutiny',        // Vote-to-skip backend (null to disable)
  msgEndpoint: '/msg/drop',               // Listener message backend (null to disable)
  pollInterval: 10000,                     // Now-playing poll interval in ms
};
