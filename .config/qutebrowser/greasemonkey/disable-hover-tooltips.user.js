// ==UserScript==
// @name         Disable hover tooltips
// @description  Remove page-provided title attributes before QtWebEngine can show native tooltip windows.
// @match        *://*/*
// @match        file:///*
// @run-at       document-start
// @all-frames   true
// ==/UserScript==
(function () {
  'use strict';

  function clearTooltips(root) {
    if (!root || root.nodeType !== Node.ELEMENT_NODE && root.nodeType !== Node.DOCUMENT_NODE && root.nodeType !== Node.DOCUMENT_FRAGMENT_NODE) {
      return;
    }

    if (root.nodeType === Node.ELEMENT_NODE && root.hasAttribute('title')) {
      root.removeAttribute('title');
    }

    if (root.querySelectorAll) {
      for (const node of root.querySelectorAll('[title]')) {
        node.removeAttribute('title');
      }
    }
  }

  clearTooltips(document);

  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      if (mutation.type === 'attributes' && mutation.attributeName === 'title') {
        mutation.target.removeAttribute('title');
      }
      for (const node of mutation.addedNodes) {
        clearTooltips(node);
      }
    }
  });

  function start() {
    clearTooltips(document);
    if (document.documentElement) {
      observer.observe(document.documentElement, {
        attributes: true,
        attributeFilter: ['title'],
        childList: true,
        subtree: true,
      });
    }
  }

  if (document.documentElement) {
    start();
  } else {
    document.addEventListener('DOMContentLoaded', start, { once: true });
  }
})();
