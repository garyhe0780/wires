# Changelog

All notable changes to Crystal Live (`wires`) are documented here.

## 1.5.0

- Add Turbo Drive–style live navigation via `CrystalLive::LiveNavigation`.
- Intercept `data-live-navigate` links; swap `[data-live-main]` without full reload.
- Add `detach:` WebSocket protocol to tear down page components on navigation.
- Add `config.navigation_enabled` and `config.main_selector` for the polyfill.
- Add `LiveLayout#render_page` for navigation-aware layouts.
- Add `examples/navigation/app.cr` multi-page demo.

## 1.4.0

- Add optional CSRF protection for client events (`config.csrf_protection`).
- Add `CrystalLive::LiveLayout` for shared page chrome.
- Add `on_mount` / `on_disconnect` lifecycle hooks.
- Tear down session components when the last WebSocket disconnects.
- Add `examples/layout/app.cr` secure dashboard example.

## 1.3.0

- Add `CrystalLive::TestKit` for capturing patches and dispatching test events.
- Add `CrystalLive::LiveDebug` and `config.debug` for protocol logging.
- Add `LiveComponent#on_error` error boundary for failed event handlers.
- Add client-side debug logging via `CrystalLiveConfig.debug`.
- Add `examples/resilient/app.cr` demonstrating error recovery.

## 1.2.0

- Add `CrystalLive.configure` for centralized configuration.
- Add `LiveRegistry` component lifecycle helpers.
- Add integration test suite and GitHub Actions CI.
- Inject runtime config into `page_html` for the polyfill.
- Add native `<template for>` detection in the polyfill.

## 1.1.0

- Add targeted inner-shadow DOM updates via `push_fragment`.
- Add optional morphing for in-place DOM updates.
- Add HTTP SSE streaming for read-only components.

## 1.0.0

- Add client event handling (`handle_event`, `live_event`, `live_input`).
- Add `LiveForm` with server-side field tracking.
- Add polyfill reconnection and heartbeat support.

## 0.3.0

- Add component registry macros (`register_live_component`, `live_component`).
- Add documentation site and dashboard example.

## 0.2.0

- Add session-scoped subscriptions and session cookies.
- Add clock and user card examples.

## 0.1.0

- Initial release: `LiveComponent`, `LiveManager`, Kemal integration, polyfill.
