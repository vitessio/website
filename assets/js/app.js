window.addEventListener('DOMContentLoaded', () => {
  const burger = document.getElementById('navbar-burger');
  burger.addEventListener('click', () => {
    const menu = document.getElementById('navbar-menu');
    [burger, menu].forEach(el => el.classList.toggle('is-active'));
  });
});
