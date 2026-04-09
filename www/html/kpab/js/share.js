function shareStation() {
  if (navigator.share) {
    navigator.share({
      title: STATION.name + ' \u2014 ' + STATION.tagline,
      text: 'Listening to some tunes on ' + STATION.name + '. Come vibe with us.',
      url: STATION.url
    }).catch(() => {});
  } else if (navigator.clipboard) {
    navigator.clipboard.writeText(STATION.url).then(() => {
      alert('Link copied to clipboard!');
    }).catch(() => {});
  }
}
