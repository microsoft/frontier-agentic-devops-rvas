/* Shared delivery-assurance standard page. */
(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', async () => {
    const body = document.getElementById('assuranceBody');
    if (!body) return;

    try {
      const response = await fetch('assets/data/delivery-assurance.md', { cache: 'no-cache' });
      if (!response.ok) throw new Error('HTTP ' + response.status);
      FP.renderMd(await response.text(), body);
    } catch (error) {
      body.innerHTML = '<p class="text-dim">Could not load the delivery assurance standard.</p>';
    }
  });
})();
