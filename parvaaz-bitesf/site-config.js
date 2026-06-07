// تنظیمات دامنه — منبع: app.config.json
window.PARVAAZ = {
  domains: [],
  primaryDomain: 'presf.ir',
  siteName: 'موسسه محمود | پلتفرم پرواز',
  cloudCore: 'netafraz-php',
  localApi: '/api/chat',
  cloudApi: '/api/chat'
};

function applyAppConfig(cfg) {
  if (!cfg) return;
  if (cfg.domains?.length) PARVAAZ.domains = cfg.domains;
  if (cfg.primaryDomain) PARVAAZ.primaryDomain = cfg.primaryDomain;
  if (cfg.siteName) PARVAAZ.siteName = cfg.siteName;
  if (cfg.hosting?.provider) PARVAAZ.cloudCore = cfg.hosting.provider;
  applySiteBranding();
}

window.getSiteDomain = function () {
  const h = location.hostname.toLowerCase();
  if (h === 'localhost' || h === '127.0.0.1') return PARVAAZ.primaryDomain;
  if (PARVAAZ.domains.includes(h)) {
    return h.startsWith('www.') ? h.slice(4) : h;
  }
  return PARVAAZ.primaryDomain;
};

window.getApiUrl = function () {
  return PARVAAZ.localApi;
};

window.applySiteBranding = function () {
  const domain = getSiteDomain();
  const canon = document.getElementById('canonical-link');
  if (canon) canon.href = 'https://' + domain + '/';
};

fetch('/app.config.json')
  .then(function (r) { return r.ok ? r.json() : null; })
  .then(applyAppConfig)
  .catch(function () {});
