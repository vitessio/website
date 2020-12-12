const tocifyOptions = {
  context: '.is-docs-content',
  selectors: 'h2,h3',
  showAndHide: false,
  smoothScroll: true,
  scrollTo: $('.navbar').height() + 25
}

function elementExists(selector) {
  return $(selector).length > 0;
}

function navbarBurgerToggle() {
  const burger = $('.navbar-burger'),
        menu   = $('.navbar-menu');

  burger.click(function() {
    [burger, menu].forEach(function(el) {
      el.toggleClass('is-active');
    });
  });
}

function linkClickOffset() {
  const navbarHeight = $('.navbar').height();
  const extraPadding = 20;
  const navbarOffset = -1 * (navbarHeight + extraPadding);
  var shiftWindow = function() { scrollBy(0, navbarOffset) };
  window.addEventListener("hashchange", shiftWindow);
  window.addEventListener("pageshow", shiftWindow);
  function load() { if (window.location.hash) shiftWindow(); }
}

function fixUponScroll() {
  if (elementExists('.docs-article')) {
    const toc = $('.toc'),
          threshold = $('.toc').offset().top;

    $(document).scroll(function() {
      console.log("SCROLLING");
    });

    $(window).scroll(function() {
      console.log('scrolling...');

      if ($(window).scrollTop() > threshold) {
        toc.css('top', `${topMargin}px`);
        toc.addClass('is-fixed');
      } else {
        toc.removeClass('is-fixed');
      }
    });
  }
}

function showAndHideTitle() {
  if (elementExists('.docs-article')) {
    
  }
}

function tableOfContents(options) {
  $('#tableOfContents').tocify(options);
}

const focusSearchInput = (keydownEvent) => {
  // Don't propagate keydown event since that'll add a "/" character to the search input.
  keydownEvent.preventDefault()
  const searchBar = document.querySelector('input#search-bar')
  if (searchBar && typeof searchBar.focus === 'function') {
    searchBar.focus()
  }
}

const HOTKEYS = {
  "/": focusSearchInput,
}

const onGlobalKeydown = (e) => {
  const target = e.target || e.srcElement;
  const { tagName } = target;

  // Don't apply hotkeys to any keypress event from an editable element, like an input.
  // Inspired by https://github.com/jaywcjlove/hotkeys <3
  const isContentEditable = target.isContentEditable || ((tagName === 'INPUT' || tagName === 'TEXTAREA' || tagName === 'SELECT') && !target.readOnly)
  if (isContentEditable) return;

  if (e.key in HOTKEYS && typeof HOTKEYS[e.key] === 'function') {
    HOTKEYS[e.key](e)
  }
}

$(function() {
  document.addEventListener('keydown', onGlobalKeydown)

  navbarBurgerToggle();
  fixUponScroll();
  tableOfContents(tocifyOptions);
  showAndHideTitle();
  linkClickOffset();
});
