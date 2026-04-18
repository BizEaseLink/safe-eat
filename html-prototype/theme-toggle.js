const STORAGE_KEY = 'safe-eat-prototype-theme';
const THEMES = ['light', 'dark'];

const resolveTheme = () => {
  const savedTheme = window.localStorage.getItem(STORAGE_KEY);
  if (THEMES.includes(savedTheme)) {
    return savedTheme;
  }
  return 'light';
};

const applyTheme = (theme) => {
  document.documentElement.dataset.theme = theme;
  window.localStorage.setItem(STORAGE_KEY, theme);

  document.querySelectorAll('.theme-switch-button').forEach((button) => {
    const isActive = button.dataset.theme === theme;
    button.classList.toggle('is-active', isActive);
    button.setAttribute('aria-pressed', String(isActive));
  });
};

const mountThemeSwitch = () => {
  if (document.querySelector('.theme-switch')) {
    return;
  }

  const switcher = document.createElement('div');
  switcher.className = 'theme-switch';
  switcher.setAttribute('role', 'group');
  switcher.setAttribute('aria-label', '切换浅色或夜晚模式');

  THEMES.forEach((theme) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'theme-switch-button';
    button.dataset.theme = theme;
    button.textContent = theme === 'light' ? '浅色' : '夜晚';
    button.addEventListener('click', () => applyTheme(theme));
    switcher.appendChild(button);
  });

  document.body.appendChild(switcher);
};

document.addEventListener('DOMContentLoaded', () => {
  mountThemeSwitch();
  applyTheme(resolveTheme());
});
