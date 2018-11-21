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

$(function() {
  navbarBurgerToggle();
  fixUponScroll();
  tableOfContents(tocifyOptions);
  showAndHideTitle();
  linkClickOffset();
});
