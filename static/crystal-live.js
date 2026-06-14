(function () {
  "use strict";

  var MARKER_RE = /^\?\s*marker\s+name="([^"]+)"\?\s*$/i;
  var EVENT_PREFIX = "event:";
  var cfg = window.CrystalLiveConfig || {};
  var WS_PATH = cfg.wsPath || "/live";
  var STREAM_PATH = cfg.streamPath || "/live/stream";
  var DEBUG = !!cfg.debug;
  var CSRF_TOKEN = cfg.csrfToken || null;
  var NAVIGATION_ENABLED = cfg.navigationEnabled !== false;
  var MAIN_SELECTOR = cfg.mainSelector || "[data-live-main]";
  var HEARTBEAT_INTERVAL = cfg.heartbeatIntervalMs || 30000;
  var HEARTBEAT_TIMEOUT = cfg.heartbeatTimeoutMs || 10000;
  var reconnectDelay = cfg.reconnectDelayMs || 1000;
  var maxReconnectDelay = cfg.reconnectMaxDelayMs || 30000;

  function debugLog() {
    if (!DEBUG) return;
    var args = ["[crystal-live]"].concat(Array.prototype.slice.call(arguments));
    console.log.apply(console, args);
  }

  var slots = new Map();
  var ws = null;
  var eventSource = null;
  var heartbeatTimer = null;
  var pongTimer = null;
  var reconnectTimer = null;

  function scanMarkers(root) {
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_COMMENT);
    var node = walker.nextNode();
    while (node) {
      var match = node.textContent && node.textContent.match(MARKER_RE);
      if (match) {
        var rootEl = findComponentRoot(node);
        if (rootEl) {
          slots.set(match[1], { marker: node, root: rootEl });
        }
      }
      node = walker.nextNode();
    }
  }

  function findComponentRoot(marker) {
    var node = marker.nextSibling;
    while (node) {
      if (node.nodeType === Node.ELEMENT_NODE && node.getAttribute("data-live-component")) {
        return node;
      }
      if (node.nodeType === Node.ELEMENT_NODE) {
        return node;
      }
      node = node.nextSibling;
    }
    return null;
  }

  function componentIdForNode(node) {
    while (node) {
      if (node.getAttribute && node.getAttribute("data-live-component")) {
        return node.getAttribute("data-live-component");
      }
      node = node.parentNode || node.host;
    }
    return null;
  }

  function findInPath(path, selectorFn) {
    for (var i = 0; i < path.length; i++) {
      var el = path[i];
      if (el && el.getAttribute && selectorFn(el)) {
        return el;
      }
    }
    return null;
  }

  function getShadowRoot(componentRoot) {
    return componentRoot.shadowRoot || componentRoot;
  }

  function setUnsafe(element, html) {
    if (typeof element.setHTMLUnsafe === "function") {
      element.setHTMLUnsafe(html, { shadowRoots: "open" });
      return;
    }
    element.innerHTML = html;
  }

  function parseHTML(html) {
    var template = document.createElement("template");
    setUnsafe(template, html.trim());
    return template.content;
  }

  function morphNode(from, to) {
    if (!to) return from;

    if (from.nodeType === Node.TEXT_NODE && to.nodeType === Node.TEXT_NODE) {
      if (from.textContent !== to.textContent) {
        from.textContent = to.textContent;
      }
      return from;
    }

    if (from.nodeType !== Node.ELEMENT_NODE || to.nodeType !== Node.ELEMENT_NODE) {
      return from;
    }

    Array.from(from.attributes).forEach(function (attr) {
      if (!to.hasAttribute(attr.name)) {
        from.removeAttribute(attr.name);
      }
    });

    Array.from(to.attributes).forEach(function (attr) {
      if (from.getAttribute(attr.name) !== attr.value) {
        from.setAttribute(attr.name, attr.value);
      }
    });

    var fromChildren = Array.from(from.childNodes);
    var toChildren = Array.from(to.childNodes);
    var max = Math.max(fromChildren.length, toChildren.length);

    for (var i = 0; i < max; i++) {
      if (!fromChildren[i] && toChildren[i]) {
        from.appendChild(toChildren[i].cloneNode(true));
      } else if (fromChildren[i] && !toChildren[i]) {
        fromChildren[i].remove();
      } else if (fromChildren[i] && toChildren[i]) {
        morphNode(fromChildren[i], toChildren[i]);
      }
    }

    return from;
  }

  function replaceComponent(slot, newRoot, name) {
    slot.root.replaceWith(newRoot);
    if (slot.marker && slot.marker.parentNode) {
      slot.marker.parentNode.removeChild(slot.marker);
    }
    slots.set(name, { marker: null, root: newRoot });
  }

  function applyTargetedPatch(slot, patch, targetSelector, morph) {
    var root = getShadowRoot(slot.root);
    var target = root.querySelector(targetSelector);
    if (!target) return false;

    var wrapper = document.createElement("div");
    while (patch.content.firstChild) {
      wrapper.appendChild(patch.content.firstChild);
    }

    var newNode = wrapper.firstElementChild || wrapper.firstChild;
    if (!newNode) return false;

    if (morph && newNode.nodeType === Node.ELEMENT_NODE) {
      morphNode(target, newNode);
      return true;
    }

    if (newNode.nodeType === Node.ELEMENT_NODE) {
      target.replaceWith(newNode);
    } else {
      target.textContent = newNode.textContent;
    }

    return true;
  }

  function supportsNativePartialUpdates() {
    if (!window.HTMLTemplateElement) return false;
    var probe = document.createElement("template");
    return "for" in probe;
  }

  function applyNativePatch(html) {
    var container = document.createElement("div");
    setUnsafe(container, html.trim());
    while (container.firstChild) {
      document.body.appendChild(container.firstChild);
    }
  }

  function applyPatch(html) {
    if (supportsNativePartialUpdates()) {
      applyNativePatch(html);
      scanMarkers(document);
      return;
    }

    var container = document.createElement("div");
    setUnsafe(container, html.trim());

    var patch = container.querySelector("template[for]");
    if (!patch) return;

    var name = patch.getAttribute("for");
    if (!name) return;

    var slot = slots.get(name);
    if (!slot) return;

    var targetSelector = patch.getAttribute("data-live-target");
    var morph = patch.getAttribute("data-live-morph") === "true";

    if (targetSelector && applyTargetedPatch(slot, patch, targetSelector, morph)) {
      return;
    }

    var wrapper = document.createElement("div");
    while (patch.content.firstChild) {
      wrapper.appendChild(patch.content.firstChild);
    }

    var newRoot = wrapper.firstElementChild;
    if (!newRoot) return;

    replaceComponent(slot, newRoot, name);
  }

  function applyStreamPayload(raw) {
    try {
      var payload = JSON.parse(raw);
      if (payload && payload.html) {
        applyPatch(payload.html);
      }
    } catch (_error) {
      applyPatch(raw);
    }
  }

  function isReadonly(slot) {
    return slot.root.hasAttribute("data-live-readonly");
  }

  function websocketComponents() {
    var names = [];
    slots.forEach(function (slot, name) {
      if (!isReadonly(slot)) {
        names.push(name);
      }
    });
    return names;
  }

  function readonlyComponents() {
    var names = [];
    slots.forEach(function (slot, name) {
      if (isReadonly(slot)) {
        names.push(name);
      }
    });
    return names;
  }

  function sendEvent(componentId, eventName, payload) {
    if (!ws || ws.readyState !== WebSocket.OPEN) return;

    if (CSRF_TOKEN) {
      payload = payload || {};
      payload._csrf = CSRF_TOKEN;
    }

    var message = EVENT_PREFIX + componentId + ":" + eventName;
    if (payload) {
      message += ":" + JSON.stringify(payload);
    }
    ws.send(message);
  }

  function resubscribe() {
    websocketComponents().forEach(function (name) {
      ws.send("subscribe:" + name);
    });
  }

  function connectStream() {
    var components = readonlyComponents();
    if (!components.length) return;

    if (eventSource) {
      eventSource.close();
      eventSource = null;
    }

    if (!STREAM_PATH) return;

    var url = STREAM_PATH + "?components=" + encodeURIComponent(components.join(","));
    eventSource = new EventSource(url);
    eventSource.onmessage = function (event) {
      debugLog("sse patch", event.data.slice(0, 80));
      applyStreamPayload(event.data);
    };
  }

  function stopHeartbeat() {
    if (heartbeatTimer) {
      clearInterval(heartbeatTimer);
      heartbeatTimer = null;
    }
    if (pongTimer) {
      clearTimeout(pongTimer);
      pongTimer = null;
    }
  }

  function startHeartbeat() {
    stopHeartbeat();
    heartbeatTimer = setInterval(function () {
      if (!ws || ws.readyState !== WebSocket.OPEN) return;
      ws.send("ping");
      pongTimer = setTimeout(function () {
        ws.close();
      }, HEARTBEAT_TIMEOUT);
    }, HEARTBEAT_INTERVAL);
  }

  function scheduleReconnect() {
    if (reconnectTimer) return;
    reconnectTimer = setTimeout(function () {
      reconnectTimer = null;
      connect();
      reconnectDelay = Math.min(reconnectDelay * 2, maxReconnectDelay);
    }, reconnectDelay);
  }

  function connectWebSocket() {
    if (!websocketComponents().length) {
      return;
    }

    if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
      return;
    }

    var protocol = location.protocol === "https:" ? "wss:" : "ws:";
    ws = new WebSocket(protocol + "//" + location.host + WS_PATH);

    ws.onopen = function () {
      debugLog("websocket connected");
      reconnectDelay = 1000;
      resubscribe();
      startHeartbeat();
    };

    ws.onmessage = function (event) {
      if (typeof event.data !== "string") return;

      if (event.data === "pong") {
        if (pongTimer) {
          clearTimeout(pongTimer);
          pongTimer = null;
        }
        return;
      }

      applyPatch(event.data);
    };

    ws.onclose = function () {
      stopHeartbeat();
      scheduleReconnect();
    };

    ws.onerror = function () {
      if (ws) ws.close();
    };
  }

  function connect() {
    connectStream();
    connectWebSocket();
  }

  function refreshTransport() {
    connectStream();
    if (!websocketComponents().length) {
      return;
    }

    if (ws && ws.readyState === WebSocket.OPEN) {
      resubscribe();
      return;
    }

    connectWebSocket();
  }

  function detachAllComponents() {
    if (ws && ws.readyState === WebSocket.OPEN) {
      slots.forEach(function (_slot, name) {
        ws.send("detach:" + name);
      });
    }
    slots.clear();
  }

  function navigateTo(url, pushState) {
    fetch(url, {
      headers: {
        "Crystal-Live-Navigation": "true",
        Accept: "text/html"
      },
      credentials: "same-origin"
    })
      .then(function (response) {
        var title = response.headers.get("Crystal-Live-Title");
        return response.text().then(function (html) {
          return { html: html, title: title };
        });
      })
      .then(function (result) {
        var main = document.querySelector(MAIN_SELECTOR);
        if (!main) {
          window.location.href = url;
          return;
        }

        detachAllComponents();
        setUnsafe(main, result.html);
        if (result.title) {
          document.title = result.title;
        }
        scanMarkers(main);
        refreshTransport();

        if (pushState !== false) {
          history.pushState({ liveNavigation: true }, "", url);
        }
      })
      .catch(function (error) {
        debugLog("navigation failed", error);
        window.location.href = url;
      });
  }

  function bindNavigation() {
    if (!NAVIGATION_ENABLED) return;

    document.addEventListener("click", function (event) {
      if (event.defaultPrevented) return;

      var path = event.composedPath();
      var link = findInPath(path, function (el) {
        return el.tagName === "A" && el.hasAttribute("data-live-navigate");
      });
      if (!link) return;
      if (link.target === "_blank") return;

      var href = link.getAttribute("href");
      if (!href || href.charAt(0) === "#") return;
      if (link.origin && link.origin !== location.origin) return;

      event.preventDefault();
      navigateTo(link.href, true);
    });

    window.addEventListener("popstate", function () {
      navigateTo(location.href, false);
    });
  }

  function bindEvents() {
    document.addEventListener("click", function (event) {
      var path = event.composedPath();
      var target = findInPath(path, function (el) {
        return el.hasAttribute("data-live-event");
      });
      if (!target) return;

      var componentId = componentIdForNode(target);
      if (!componentId) return;

      sendEvent(componentId, target.getAttribute("data-live-event"));
    });

    document.addEventListener("input", function (event) {
      var path = event.composedPath();
      var target = findInPath(path, function (el) {
        return el.hasAttribute("data-live-input");
      });
      if (!target) return;

      var componentId = componentIdForNode(target);
      if (!componentId) return;

      sendEvent(componentId, "input", {
        field: target.getAttribute("data-live-input"),
        value: target.value
      });
    });

    document.addEventListener("submit", function (event) {
      var path = event.composedPath();
      var form = findInPath(path, function (el) {
        return el.tagName === "FORM" && el.hasAttribute("data-live-form");
      });
      if (!form) return;

      event.preventDefault();

      var componentId = componentIdForNode(form);
      if (!componentId) return;

      sendEvent(componentId, "submit");
    });
  }

  scanMarkers(document);
  bindEvents();
  bindNavigation();

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", connect);
  } else {
    connect();
  }
})();
