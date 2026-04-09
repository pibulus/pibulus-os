(function() {
  const mutinyToggle = document.getElementById('mutinyToggle');
  const mutinyPanel = document.getElementById('mutinyPanel');
  const mutinyStatus = document.getElementById('mutinyStatus');
  const mutinyDesc = document.getElementById('mutinyDesc');
  const mutinyFire = document.getElementById('mutinyFire');
  const mutinyToast = document.getElementById('mutinyToast');
  let mutinyCooldown = false;
  let cooldownTick = null;

  function showMutinyToast(msg, duration = 3000) {
    mutinyToast.textContent = msg;
    mutinyToast.classList.add('show');
    setTimeout(() => mutinyToast.classList.remove('show'), duration);
  }

  function setMutinyCooldown(seconds) {
    mutinyCooldown = true;
    if (cooldownTick) clearInterval(cooldownTick);
    mutinyToggle.classList.add('cooldown');
    mutinyFire.disabled = true;
    mutinyFire.style.opacity = '0.3';
    mutinyFire.style.cursor = 'not-allowed';
    mutinyStatus.textContent = 'COOLING DOWN';
    mutinyDesc.textContent = 'Mutiny on cooldown. Try again in a few minutes.';
    const end = Date.now() + seconds * 1000;
    cooldownTick = setInterval(() => {
      const left = Math.max(0, Math.ceil((end - Date.now()) / 1000));
      if (left <= 0) {
        clearInterval(cooldownTick);
        cooldownTick = null;
        mutinyCooldown = false;
        mutinyToggle.classList.remove('cooldown');
        mutinyToggle.innerHTML = '&#x2620; MUTINY';
        mutinyFire.disabled = false;
        mutinyFire.style.opacity = '1';
        mutinyFire.style.cursor = 'pointer';
        mutinyFire.innerHTML = '&#x2620; WALK THE PLANK';
        mutinyStatus.textContent = 'READY';
        mutinyDesc.textContent = "Don't like what's playing? Skip it. One skip every 10 minutes.";
        return;
      }
      const display = left > 60 ? Math.ceil(left/60) + 'm' : left + 's';
      mutinyToggle.innerHTML = '&#x2620; MUTINY (' + display + ')';
    }, 1000);
  }

  mutinyToggle.addEventListener('click', () => {
    const isOpen = mutinyPanel.classList.contains('open');
    mutinyPanel.classList.toggle('open');
    if (!mutinyCooldown) {
      mutinyToggle.innerHTML = isOpen ? '&#x2620; MUTINY' : '&#x2620; Close';
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && mutinyPanel.classList.contains('open')) {
      mutinyPanel.classList.remove('open');
      if (!mutinyCooldown) mutinyToggle.innerHTML = '&#x2620; MUTINY';
    }
  });

  mutinyFire.addEventListener('click', async () => {
    if (mutinyCooldown) return;
    mutinyFire.disabled = true;
    mutinyFire.textContent = '...';
    try {
      const res = await fetch(STATION.mutinyEndpoint, { method: 'POST' });
      const data = await res.json();
      if (res.status === 429) {
        mutinyPanel.classList.remove('open');
        setMutinyCooldown(data.remaining || 600);
        return;
      }
      if (data.action === 'skipped') {
        mutinyPanel.classList.remove('open');
        mutinyToggle.innerHTML = '&#x2620; SKIPPED!';
        showMutinyToast('Track walked the plank.');
        setTimeout(() => setMutinyCooldown(data.remaining || 600), 1500);
      } else {
        showMutinyToast(data.message || 'Mutiny failed. Radio resists.');
        mutinyFire.innerHTML = '&#x2620; WALK THE PLANK';
        mutinyFire.disabled = false;
      }
    } catch (e) {
      showMutinyToast('Mutiny failed. Radio resists.');
      mutinyFire.innerHTML = '&#x2620; WALK THE PLANK';
      mutinyFire.disabled = false;
    }
  });
})();
