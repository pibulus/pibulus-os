(function() {
  const aboutToggle = document.getElementById('aboutToggle');
  const aboutPanel = document.getElementById('aboutPanel');
  aboutToggle.addEventListener('click', () => {
    const isOpen = aboutPanel.classList.contains('open');
    aboutPanel.classList.toggle('open');
    aboutToggle.innerHTML = isOpen ? '&#x2139; About / FAQ' : '&#x2139; Close';
  });
})();
