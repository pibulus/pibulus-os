(function() {
  const msgSection = document.getElementById('msgSection');
  const msgToggle = document.getElementById('msgToggle');
  const msgName = document.getElementById('msgName');
  const msgText = document.getElementById('msgText');
  const msgSend = document.getElementById('msgSend');
  const msgStatus = document.getElementById('msgStatus');

  msgToggle.addEventListener('click', () => {
    const isOpen = msgSection.classList.contains('open');
    msgSection.classList.toggle('open');
    msgToggle.innerHTML = isOpen
      ? '<span class="msg-toggle-text">&#x1F4EC; DROP A MESSAGE</span>'
      : '&#x1F4EC; Close';
    if (!isOpen) setTimeout(() => msgText.focus(), 400);
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && msgSection.classList.contains('open')) {
      msgSection.classList.remove('open');
      msgToggle.innerHTML = '<span class="msg-toggle-text">&#x1F4EC; DROP A MESSAGE</span>';
    }
  });

  msgSend.addEventListener('click', async () => {
    const text = msgText.value.trim();
    if (!text) return;

    msgSend.disabled = true;
    msgSend.textContent = '...';
    msgStatus.textContent = '';
    msgStatus.className = 'msg-status';

    try {
      const res = await fetch(STATION.msgEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: msgName.value.trim() || 'Anonymous listener',
          message: text,
          source: STATION.name
        })
      });

      if (res.ok) {
        msgStatus.textContent = 'SENT \u2713';
        msgStatus.className = 'msg-status ok';
        msgText.value = '';
        setTimeout(() => {
          msgSection.classList.remove('open');
          msgStatus.textContent = '';
          msgSend.disabled = false;
          msgSend.textContent = 'SEND';
        }, 2000);
        return;
      } else {
        const data = await res.json().catch(() => ({}));
        msgStatus.textContent = data.error || 'Failed to send';
        msgStatus.className = 'msg-status err';
      }
    } catch (e) {
      msgStatus.textContent = 'Network error';
      msgStatus.className = 'msg-status err';
    }

    msgSend.disabled = false;
    msgSend.textContent = 'SEND';
  });
})();
