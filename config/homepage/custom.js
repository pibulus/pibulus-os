// PABLO_OS RADIO SUBSYSTEM
console.log("Initializing SomaFM Uplink...");

// Create the Floating Hacker Button
const radioContainer = document.createElement('div');
radioContainer.style.position = 'fixed';
radioContainer.style.bottom = '20px';
radioContainer.style.right = '20px';
radioContainer.style.zIndex = '9999';
radioContainer.style.background = '#000';
radioContainer.style.border = '2px solid #00ffea'; // Cyan Border
radioContainer.style.boxShadow = '4px 4px 0px #ff00ff'; // Pink Shadow
radioContainer.style.padding = '12px';
radioContainer.style.cursor = 'pointer';
radioContainer.style.fontFamily = "'VT323', monospace";
radioContainer.style.fontSize = "18px";
radioContainer.style.userSelect = "none";
radioContainer.innerHTML = '<span style="color:#fcee0a;">[ CONNECT_SOMA_FM ]</span>';
radioContainer.style.bottom = '20px';
radioContainer.style.right = 'auto'; // Clear the right alignment
radioContainer.style.left = '20px';  // Move to LEFT

// SomaFM Groove Salad Stream (128k MP3)
const audio = new Audio('https://ice2.somafm.com/groovesalad-128-mp3');
let isPlaying = false;

radioContainer.onclick = function() {
    if (!isPlaying) {
        audio.play();
        // Change aesthetic to "Live"
        radioContainer.innerHTML = '<span style="color:#ff00ff; animation: blink 1s infinite;">[ /// SIGNAL_LOCKED /// ]</span>';
        radioContainer.style.borderColor = '#ff00ff';
        isPlaying = true;
    } else {
        audio.pause();
        // Change aesthetic back to "Standby"
        radioContainer.innerHTML = '<span style="color:#fcee0a;">[ CONNECT_SOMA_FM ]</span>';
        radioContainer.style.borderColor = '#00ffea';
        isPlaying = false;
    }
};

// Add a simple blink animation for the "ON AIR" text
const style = document.createElement('style');
style.innerHTML = `
  @keyframes blink {
    0% { opacity: 1; }
    50% { opacity: 0.5; }
    100% { opacity: 1; }
  }
`;
document.head.appendChild(style);
document.body.appendChild(radioContainer);
